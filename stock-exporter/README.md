# Stock Exporter - Prometheus Metrics for Stock Market Data

Polls [Twelve Data](https://twelvedata.com) for configured tickers and exposes a `/metrics` endpoint for Prometheus to scrape. Supports a **demo mode** with realistic mock data for testing without an API key.

## Quick Start

```bash
# Start in demo mode (mock data, no API key needed)
docker-compose up -d --build

# View logs
docker-compose logs -f stock-exporter

# Stop
docker-compose down
```

Metrics available at: http://localhost:8000/metrics

## Modes

### Demo Mode (default in docker-compose)

Generates realistic mock stock data — perfect for testing the full Prometheus → Grafana pipeline.

```yaml
environment:
  DEMO_MODE: "true"
```

### Live Mode (Twelve Data API)

1. Sign up for a free key at https://twelvedata.com/pricing (800 calls/day)
2. Update `docker-compose.yml`:

```yaml
environment:
  DEMO_MODE: "false"
  TWELVE_DATA_API_KEY: "your-api-key"
```

All tickers are fetched in a single batch request (1 API credit per cycle). At the default 5m interval that's ~288 calls/day — well within the free tier.

## Configuration

Edit [stocks.yaml](stocks.yaml) to control which tickers are tracked and how often:

```yaml
interval: 5m   # poll frequency (s / m / h)

tickers:
  - AAPL
  - NVDA
  - SPY
```

Restart the container after any change:

```bash
docker-compose restart stock-exporter
```

## Metrics Reference

| Metric | Description |
|--------|-------------|
| `stock_price_current` | Latest trade price (USD) |
| `stock_price_open` | Session open price (USD) |
| `stock_price_day_high` | Intraday high (USD) |
| `stock_price_day_low` | Intraday low (USD) |
| `stock_price_52w_high` | 52-week high (USD) |
| `stock_price_52w_low` | 52-week low (USD) |
| `stock_volume` | Shares traded |
| `stock_change_percent` | % change vs previous close |
| `stock_scrape_success` | `1` = last fetch OK, `0` = failed |
| `stock_scrape_errors_total` | Cumulative fetch errors per ticker |
| `stock_scrape_duration_seconds` | Time taken for last full cycle |

All metrics carry label: `ticker`.

## Prometheus Integration

The Prometheus scrape job is already configured in [prometheus/prometheus.yml](../prometheus/prometheus.yml):

```yaml
- job_name: 'stock-exporter'
  scrape_interval: 5m
  scrape_timeout: 30s
  static_configs:
    - targets: ['host.docker.internal:8000']
```

## Sample PromQL Queries

```promql
# Current price for all tickers
stock_price_current

# % change vs previous close — sorted descending
sort_desc(stock_change_percent)

# Tickers down more than 3% today
stock_change_percent < -3

# Volume spike — 2× the 7-day average
stock_volume > 2 * avg_over_time(stock_volume[7d])

# Distance from 52-week high (%)
(stock_price_52w_high - stock_price_current) / stock_price_52w_high * 100
```
- Data is unavailable outside market hours; `stock_scrape_success` will show `0` if the ticker returns no price.
- For real-time data, swap the provider for Alpaca or Twelve Data and update `main.py`.

## Directory Structure

```
stock-exporter/
├── main.py            # Exporter logic
├── stocks.yaml        # Ticker list and poll interval
├── requirements.txt   # Python dependencies
├── Dockerfile
├── docker-compose.yml
└── README.md
```
