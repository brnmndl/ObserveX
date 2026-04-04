#!/usr/bin/env python3
"""
Stock Price Prometheus Exporter
Fetches stock prices from Twelve Data (https://twelvedata.com) and exposes
/metrics for Prometheus to scrape.

Set TWELVE_DATA_API_KEY env var with your free key (800 calls/day).
Set DEMO_MODE=true to generate realistic mock data without any API key.
"""

import logging
import math
import os
import random
import time
from threading import Thread

import requests
import yaml
from prometheus_client import Counter, Gauge, start_http_server

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
log = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

API_KEY = os.getenv("TWELVE_DATA_API_KEY", "demo")
DEMO_MODE = os.getenv("DEMO_MODE", "").lower() in ("true", "1", "yes")
_TD_URL = "https://api.twelvedata.com/quote"

# Tickers that work with the free "demo" API key (no signup needed)
_DEMO_KEY_TICKERS = {"AAPL"}

# ---------------------------------------------------------------------------
# Metrics
# ---------------------------------------------------------------------------

_LABELS = ["ticker"]

STOCK_PRICE_CURRENT = Gauge(
    "stock_price_current",
    "Latest close price from the most recent trading session (USD)",
    _LABELS,
)
STOCK_PRICE_OPEN = Gauge(
    "stock_price_open",
    "Open price of the most recent trading session (USD)",
    _LABELS,
)
STOCK_PRICE_DAY_HIGH = Gauge(
    "stock_price_day_high",
    "Intraday high of the most recent session (USD)",
    _LABELS,
)
STOCK_PRICE_DAY_LOW = Gauge(
    "stock_price_day_low",
    "Intraday low of the most recent session (USD)",
    _LABELS,
)
STOCK_VOLUME = Gauge(
    "stock_volume",
    "Trading volume of the most recent session (shares)",
    _LABELS,
)
STOCK_CHANGE_PCT = Gauge(
    "stock_change_percent",
    "Price change % vs the prior session close",
    _LABELS,
)
STOCK_PRICE_52W_HIGH = Gauge(
    "stock_price_52w_high",
    "52-week high price (USD)",
    _LABELS,
)
STOCK_PRICE_52W_LOW = Gauge(
    "stock_price_52w_low",
    "52-week low price (USD)",
    _LABELS,
)

SCRAPE_SUCCESS = Gauge(
    "stock_scrape_success",
    "1 if the last batch fetch succeeded, 0 if it failed",
    _LABELS,
)
SCRAPE_ERRORS_TOTAL = Counter(
    "stock_scrape_errors_total",
    "Cumulative fetch errors",
    _LABELS,
)
SCRAPE_DURATION = Gauge(
    "stock_scrape_duration_seconds",
    "Wall-clock time taken for the last full fetch cycle",
)


# ---------------------------------------------------------------------------
# Mock data for DEMO_MODE — random-walk prices that build on previous values
# ---------------------------------------------------------------------------

_MOCK_SEEDS = {
    "AAPL": 255.0, "MSFT": 425.0, "GOOGL": 165.0, "NVDA": 120.0,
    "META": 580.0, "AMZN": 195.0, "TSLA": 260.0, "SPY": 565.0,
    "QQQ": 485.0,  "VTI": 280.0,
}

# Tracks the last price per ticker so each cycle walks from the previous one
_mock_state: dict[str, float] = {}


def _mock_quote(symbol: str) -> dict:
    prev = _mock_state.get(symbol, _MOCK_SEEDS.get(symbol, 100.0 + hash(symbol) % 400))

    # Random walk: ~0.3% std-dev per step, slight mean-reversion toward seed
    seed = _MOCK_SEEDS.get(symbol, prev)
    revert = (seed - prev) / seed * 0.02  # gentle pull back toward seed
    step = random.gauss(revert, 0.003)
    close = round(prev * (1 + step), 2)
    close = max(close, 1.0)  # floor at $1

    _mock_state[symbol] = close

    open_ = round(prev, 2)  # open = previous close (realistic)
    high = round(max(close, open_) * random.uniform(1.001, 1.008), 2)
    low = round(min(close, open_) * random.uniform(0.992, 0.999), 2)
    pct = round((close - prev) / prev * 100, 4)
    vol = random.randint(10_000_000, 80_000_000)
    return {
        "close": str(close), "open": str(open_), "high": str(high),
        "low": str(low), "volume": str(vol), "previous_close": str(prev),
        "percent_change": str(pct),
        "fifty_two_week": {
            "high": str(round(seed * 1.25, 2)),
            "low": str(round(seed * 0.65, 2)),
        },
    }


# ---------------------------------------------------------------------------
# Fetch — Twelve Data batch quote API (comma-separated symbols = 1 credit)
# ---------------------------------------------------------------------------

def fetch_batch(tickers: list[str]) -> None:
    """Fetch tickers via API where possible, mock the rest in demo mode."""
    quotes: dict[str, dict] = {}

    # Decide which tickers to fetch live vs mock
    if DEMO_MODE:
        # demo key only works for a limited set — fetch those live, mock the rest
        live = [t for t in tickers if t in _DEMO_KEY_TICKERS]
        mock = [t for t in tickers if t not in _DEMO_KEY_TICKERS]
    else:
        live = tickers
        mock = []

    # Fetch live tickers from Twelve Data
    if live:
        try:
            resp = requests.get(
                _TD_URL,
                params={"symbol": ",".join(live), "apikey": API_KEY},
                timeout=15,
            )
            resp.raise_for_status()
            data = resp.json()
            if len(live) == 1:
                quotes[live[0]] = data
            else:
                quotes.update(data)
        except Exception as exc:
            log.error("Twelve Data API error: %s", exc)
            for sym in live:
                SCRAPE_SUCCESS.labels(sym).set(0)
                SCRAPE_ERRORS_TOTAL.labels(sym).inc()

    # Mock remaining tickers
    for sym in mock:
        quotes[sym] = _mock_quote(sym)

    for symbol in tickers:
        is_mock = symbol in mock
        _apply_quote(symbol, quotes.get(symbol, {}), is_mock)


def _apply_quote(symbol: str, q: dict, is_mock: bool = False) -> None:
    try:
        if "code" in q and q.get("status") == "error":
            raise ValueError(q.get("message", "API error"))

        close = float(q["close"])
        open_ = float(q["open"])
        high = float(q["high"])
        low = float(q["low"])
        vol = float(q["volume"])
        prev = float(q.get("previous_close", 0))
        pct = float(q.get("percent_change", 0))
        w52 = q.get("fifty_two_week", {})
        high_52 = float(w52.get("high", math.nan))
        low_52 = float(w52.get("low", math.nan))

        STOCK_PRICE_CURRENT.labels(symbol).set(close)
        STOCK_PRICE_OPEN.labels(symbol).set(open_)
        STOCK_PRICE_DAY_HIGH.labels(symbol).set(high)
        STOCK_PRICE_DAY_LOW.labels(symbol).set(low)
        STOCK_VOLUME.labels(symbol).set(vol)
        STOCK_CHANGE_PCT.labels(symbol).set(pct)
        STOCK_PRICE_52W_HIGH.labels(symbol).set(high_52)
        STOCK_PRICE_52W_LOW.labels(symbol).set(low_52)
        SCRAPE_SUCCESS.labels(symbol).set(1)

        log.info(
            "%-6s  price=%.2f  chg=%+.2f%%  vol=%.0f  [%s]",
            symbol, close, pct, vol, "mock" if is_mock else "live",
        )

    except Exception as exc:
        log.error("Failed %s: %s", symbol, exc)
        SCRAPE_SUCCESS.labels(symbol).set(0)
        SCRAPE_ERRORS_TOTAL.labels(symbol).inc()


# ---------------------------------------------------------------------------
# Fetch loop
# ---------------------------------------------------------------------------

def _parse_interval(raw) -> int:
    """Parse interval like '5m', '30s', '1h' into seconds."""
    if isinstance(raw, int):
        return raw
    raw = str(raw).strip()
    unit = raw[-1].lower()
    n = int(raw[:-1])
    return n * {"s": 1, "m": 60, "h": 3600}.get(unit, 60)


def run_loop(tickers: list, interval: int) -> None:
    while True:
        start = time.monotonic()
        fetch_batch(tickers)
        elapsed = time.monotonic() - start
        SCRAPE_DURATION.set(elapsed)
        sleep_for = max(0, interval - elapsed)
        log.info(
            "Cycle done in %.1fs (%d tickers) — next run in %.0fs",
            elapsed, len(tickers), sleep_for,
        )
        time.sleep(sleep_for)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    config_path = os.getenv("STOCKS_CONFIG", "/app/stocks.yaml")
    port = int(os.getenv("METRICS_PORT", "8000"))

    with open(config_path) as fh:
        cfg = yaml.safe_load(fh)

    tickers = [str(t).upper() for t in cfg.get("tickers", [])]
    interval = _parse_interval(cfg.get("interval", "5m"))

    if not tickers:
        raise ValueError("No tickers configured in stocks.yaml")

    mode = "DEMO (mock data)" if DEMO_MODE else "Twelve Data API"
    if not DEMO_MODE and not API_KEY:
        log.warning(
            "TWELVE_DATA_API_KEY not set — set it or use DEMO_MODE=true"
        )

    log.info(
        "Starting stock-exporter  mode=%s  tickers=%d  interval=%ds  port=%d",
        mode, len(tickers), interval, port,
    )

    start_http_server(port)
    Thread(target=run_loop, args=(tickers, interval), daemon=True).start()

    while True:
        time.sleep(3600)


if __name__ == "__main__":
    main()
