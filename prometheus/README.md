# Prometheus - Metrics Collection & Monitoring

A powerful open-source monitoring and alerting toolkit for collecting and storing time-series metrics data.

## Features

- **Time-Series Database**: Efficient storage for metrics
- **Powerful Querying**: PromQL for flexible metric analysis
- **Service Discovery**: Automatic target discovery
- **Alerting**: Rule-based alerting (with Alertmanager)
- **Visualization**: Built-in expression browser and integration with Grafana

## Running with Docker

```bash
# Start Prometheus and Node Exporter
docker-compose up -d

# View logs
docker-compose logs -f prometheus

# Stop services
docker-compose down
```

Prometheus will be available at: http://localhost:9090

## Components

### Prometheus Server
- **Port**: 9090
- **Retention**: 7 days
- **Scrape Interval**: 1 minute

### Node Exporter
- **Port**: 9100
- **Purpose**: Exports hardware and OS metrics (CPU, memory, disk, network)

## Configuration

The configuration is in [prometheus.yml](prometheus.yml) and includes:

### Scrape Targets

| Job Name | Target | Description |
|----------|--------|-------------|
| `prometheus` | `localhost:9090` | Prometheus self-monitoring |
| `node-exporter` | `node-exporter:9100` | System metrics |

### Adding New Targets

Edit [prometheus.yml](prometheus.yml) to add more scrape targets:

```yaml
scrape_configs:
  - job_name: 'keyjournal'
    static_configs:
      - targets: ['keyjournal:8907']
```

Then restart Prometheus:
```bash
docker-compose restart prometheus
```

## Accessing Prometheus

### Web UI
Open http://localhost:9090 in your browser to access:
- **Graph**: Query and visualize metrics
- **Alerts**: View active alerts
- **Status**: Check targets and configuration
- **Targets**: View scrape target health

### Health Check

```bash
# Check Prometheus health
curl http://localhost:9090/-/healthy

# Check ready status
curl http://localhost:9090/-/ready
```

Expected response:
```
Prometheus Server is Healthy.
```

## PromQL Query Examples

### System Metrics

```promql
# CPU usage percentage
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Disk usage percentage
(1 - (node_filesystem_avail_bytes / node_filesystem_size_bytes)) * 100

# Network traffic rate
rate(node_network_receive_bytes_total[5m])
```

### Prometheus Metrics

```promql
# Number of active targets
up

# Scrape duration
scrape_duration_seconds

# Time series count
prometheus_tsdb_head_series
```

## Integration with Grafana

### Add Prometheus as Data Source

1. Open Grafana (usually http://localhost:3000)
2. Go to **Configuration** → **Data Sources** → **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: `Prometheus`
   - **URL**: `http://localhost:9090` (if running locally) or `http://prometheus:9090` (if using Docker networks)
   - **Access**: `Server (default)`
5. Click **Save & Test**

### Import Dashboards

Popular Node Exporter dashboards:
- **Dashboard ID 1860**: Node Exporter Full
- **Dashboard ID 11074**: Node Exporter for Prometheus

## Directory Structure

```
prometheus/
├── docker-compose.yml   # Prometheus and Node Exporter services
├── prometheus.yml       # Prometheus configuration
└── README.md            # This file
```

## Data Storage

Metrics are stored in Prometheus's internal TSDB with 7-day retention.

To clear all metrics:
```bash
docker-compose down -v
```

## Troubleshooting

### Targets Down
- Check if target services are running: `docker ps`
- Verify network connectivity between containers
- Check target configuration in [prometheus.yml](prometheus.yml)
- View target status: http://localhost:9090/targets

### High Memory Usage
- Reduce retention time in docker-compose.yml
- Decrease scrape frequency in prometheus.yml
- Limit number of time series

### Configuration Errors
```bash
# Validate configuration
docker exec prometheus promtool check config /etc/prometheus/prometheus.yml

# View Prometheus logs
docker-compose logs prometheus
```

## Alerting

To add alerting, create alert rules and integrate with Alertmanager:

Example alert rule (`alerts.yml`):
```yaml
groups:
  - name: example
    rules:
      - alert: HighCPU
        expr: node_cpu_seconds_total > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
```

## Useful Commands

```bash
# Reload configuration without restart
curl -X POST http://localhost:9090/-/reload

# Check TSDB status
curl http://localhost:9090/api/v1/status/tsdb

# Query API
curl 'http://localhost:9090/api/v1/query?query=up'
```
