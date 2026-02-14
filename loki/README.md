# Loki - Log Aggregation System

A horizontally scalable, highly available log aggregation and storage system for the ObserveX monitoring stack.

## Features

- **High Performance**: Efficiently indexes and queries logs
- **Cost-Effective**: Indexes only metadata, stores logs compressed
- **Cloud Native**: Designed for Kubernetes and containerized environments
- **Flexible Querying**: LogQL query language for powerful log analysis
- **Multi-Tenancy**: Support for isolated log streams per tenant

## Running with Docker

```bash
# Start Loki
docker-compose up -d

# View logs
docker-compose logs -f loki

# Stop Loki
docker-compose down
```

Loki will be available at: http://localhost:3100

## Configuration

The configuration is in [loki-config.yml](loki-config.yml) and includes:

- **Limits**: Ingestion and query rate limits
- **Retention**: 31 days (744h) log retention
- **Storage**: Filesystem-based with TSDB index
- **Query Range**: 30 days max lookback

### Key Limits

| Setting | Value | Description |
|---------|-------|-------------|
| `ingestion_rate_mb` | 10MB/s | Per-tenant ingestion rate |
| `ingestion_burst_size_mb` | 20MB | Burst allowance |
| `per_stream_rate_limit` | 5MB/s | Per-stream rate limit |
| `retention_period` | 744h | Log retention (31 days) |
| `max_query_length` | 721h | Max query time range |
| `max_entries_limit_per_query` | 5000 | Max log lines per query |

## Sending Logs to Loki

### Using Promtail

```bash
curl -X POST http://localhost:3100/loki/api/v1/push \
  -H "Content-Type: application/json" \
  -d '{
    "streams": [
      {
        "stream": {
          "job": "keyjournal",
          "app": "keyjournal"
        },
        "values": [
          ["'$(date +%s)000000000'", "log line 1"],
          ["'$(date +%s)000000000'", "log line 2"]
        ]
      }
    ]
  }'
```

### Using Docker Log Driver

Add to your service in docker-compose.yml:
```yaml
logging:
  driver: loki
  options:
    loki-url: "http://localhost:3100/loki/api/v1/push"
    loki-batch-size: "400"
```

## Querying Logs

### LogQL Examples

```logql
# All logs from keyjournal
{app="keyjournal"}

# Filter by field
{app="keyjournal"} | json | tab_name="Test"

# Count logs per minute
count_over_time({app="keyjournal"}[1m])

# Extract and filter JSON fields
{app="keyjournal"} | json | salary > 50000
```

### Query via API

```bash
# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query_range" \
  --data-urlencode 'query={app="keyjournal"}' \
  --data-urlencode 'limit=10'
```

## Integration with Grafana

1. Add Loki as a data source in Grafana
2. URL: `http://loki:3100`
3. Use LogQL in Explore or Dashboard panels

## Directory Structure

```
loki/
├── docker-compose.yml   # Loki service definition
├── loki-config.yml      # Loki configuration
└── README.md            # This file
```

## Data Storage

Logs and index data are stored in the `loki-data` Docker volume.

To clear all logs:
```bash
docker-compose down -v
```

## Health Check

Check if Loki is running and accessible:

```bash
# Check Loki ready status (should return "ready")
curl http://localhost:3100/ready

# Check Loki metrics endpoint
curl http://localhost:3100/metrics

# Get Loki build info
curl http://localhost:3100/loki/api/v1/status/buildinfo
```

Or open in your browser:
- **Ready Status**: http://localhost:3100/ready
- **Metrics**: http://localhost:3100/metrics
- **Build Info**: http://localhost:3100/loki/api/v1/status/buildinfo

Expected response for `/ready`:
```
ready
```

## Troubleshooting

### Logs not appearing
- Verify Loki is running: `docker-compose ps`
- Check Loki logs: `docker-compose logs loki`
- Ensure network connectivity between services

### Out of memory errors
- Reduce `max_query_parallelism` in config
- Decrease `max_entries_limit_per_query`
- Increase Docker memory limits

### Ingestion rate errors
- Increase `ingestion_rate_mb` and `ingestion_burst_size_mb`
- Add more Loki instances for horizontal scaling
