# Vector - High-Performance Observability Data Pipeline

A lightweight, ultra-fast tool for building observability pipelines to collect, transform, and route logs and metrics.

## Features

- **High Performance**: Built in Rust for speed and efficiency
- **Universal**: Collect from any source, send to any sink
- **Transform**: Filter, parse, enrich, and aggregate data
- **Reliable**: Guaranteed delivery with disk buffers
- **Observable**: Built-in metrics and health checks

## Running with Docker

```bash
# Start Vector
docker-compose up -d

# View logs
docker-compose logs -f vector

# Stop Vector
docker-compose down
```

Vector will be available at:
- **API**: http://localhost:8686
- **Prometheus Metrics**: http://localhost:9598/metrics

## Configuration

The configuration is in [vector.yaml](vector.yaml) with three main sections:

### Sources (Data Inputs)

| Source | Type | Description |
|--------|------|-------------|
| `internal_metrics` | internal_metrics | Vector's own metrics |
| `docker_logs` | docker_logs | Container logs from Docker |
| `http_input` | http_server | HTTP endpoint for custom logs (port 8080) |
| `keyjournal_logs` | file | File-based log ingestion |

### Transforms (Data Processing)

| Transform | Type | Description |
|-----------|------|-------------|
| `parse_json` | remap | Parse JSON from log messages |
| `add_metadata` | remap | Add environment and timestamp metadata |

### Sinks (Data Outputs)

| Sink | Type | Destination |
|------|------|-------------|
| `loki_sink` | loki | Send logs to Loki |
| `prometheus_sink` | prometheus_exporter | Expose metrics for Prometheus |
| `console_output` | console | Debug output to console |
| `file_output` | file | Write to dated log files |

## Sending Logs to Vector

### Via HTTP

```bash
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
    "message": "Test log message",
    "level": "info",
    "app": "test"
  }'
```

### Via Docker Logs

Vector automatically collects logs from Docker containers matching the configured image names.

### Via File

Place log files in directories configured in the `file` source.

## Vector API

### Health Check

```bash
# Check Vector health
curl http://localhost:8686/health

# Get Vector metrics
curl http://localhost:9598/metrics
```

### GraphQL API

Vector provides a GraphQL API for querying components:

```bash
curl http://localhost:8686/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ health }"}'
```

## Configuration Examples

### Add Datadog Sink

```yaml
sinks:
  datadog_sink:
    type: datadog_logs
    inputs:
      - add_metadata
    endpoint: https://http-intake.logs.datadoghq.com
    default_api_key: "${DATADOG_API_KEY}"
```

### Add Elasticsearch Sink

```yaml
sinks:
  elasticsearch_sink:
    type: elasticsearch
    inputs:
      - add_metadata
    endpoint: http://elasticsearch:9200
    mode: bulk
```

### Filter Transform

```yaml
transforms:
  filter_errors:
    type: filter
    inputs:
      - parse_json
    condition:
      type: vrl
      source: '.level == "error"'
```

## VRL (Vector Remap Language)

Vector uses VRL for transformations. Common examples:

```vrl
# Parse JSON
. = parse_json!(.message)

# Add timestamp
.timestamp = now()

# Extract fields
.status_code = to_int!(.status)

# Conditional logic
if .level == "error" {
  .priority = "high"
}

# String manipulation
.app_name = upcase(.app)
```

## Integration with Loki

Vector is configured to send logs to Loki automatically. Ensure Loki is running:

```bash
cd ../loki
docker-compose up -d
```

Then Vector will forward all processed logs to Loki at `http://loki:3100`.

## Integration with Prometheus

Vector exposes its internal metrics at http://localhost:9598/metrics for Prometheus scraping.

Add to Prometheus configuration:
```yaml
scrape_configs:
  - job_name: 'vector'
    static_configs:
      - targets: ['vector:9598']
```

## Directory Structure

```
vector/
├── docker-compose.yml   # Vector service definition
├── vector.yaml          # Vector configuration
└── README.md            # This file
```

## Data Storage

Processed logs are stored in the `vector-data` Docker volume.

To clear data:
```bash
docker-compose down -v
```

## Troubleshooting

### Vector not starting
- Check configuration syntax: `docker exec vector vector validate /etc/vector/vector.yaml`
- View logs: `docker-compose logs vector`

### Logs not appearing in Loki
- Verify Loki is running: `curl http://localhost:3100/ready`
- Check Vector→Loki connectivity
- View Vector metrics: `curl http://localhost:9598/metrics | grep loki`

### High memory usage
- Reduce buffer sizes in vector.yaml
- Limit sources or add filters
- Increase flush intervals

## Monitoring Vector

```bash
# View component health
curl http://localhost:8686/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ components { sources { id status } } }"}'

# Check sink status
curl http://localhost:8686/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ components { sinks { id status } } }"}'
```

## Performance Tips

1. Use `batch` settings for sinks to reduce network overhead
2. Enable compression for network sinks
3. Use disk buffers for reliability
4. Filter early to reduce processing load
5. Use sampling for high-volume sources
