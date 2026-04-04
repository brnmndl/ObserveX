FROM python:3.12-slim

WORKDIR /app

# Install dependencies first for layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source and default config
COPY main.py .
COPY stocks.yaml .

ENV STOCKS_CONFIG=/app/stocks.yaml
ENV METRICS_PORT=8000

EXPOSE 8000

CMD ["python", "main.py"]
