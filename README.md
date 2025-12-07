# ObserveX

ObserveX is a container-native observability platform built with OpenTelemetry, Grafana, Prometheus, Loki, and Tempo. It provides a complete observability stack for metrics, logs, and traces with minimal configuration.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                         │
│         (Your services instrumented with OTEL)               │
└──────────────────────┬──────────────────────────────────────┘
                       │ OTLP (gRPC/HTTP)
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              OpenTelemetry Collector                         │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐                │
│  │ Metrics  │   │   Logs   │   │  Traces  │                │
│  │ Pipeline │   │ Pipeline │   │ Pipeline │                │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘                │
└───────┼──────────────┼──────────────┼──────────────────────┘
        │              │              │
        ▼              ▼              ▼
┌─────────────┐ ┌────────────┐ ┌────────────┐
│ Prometheus  │ │    Loki    │ │   Tempo    │
│  (Metrics)  │ │   (Logs)   │ │  (Traces)  │
└──────┬──────┘ └─────┬──────┘ └─────┬──────┘
       │              │              │
       └──────────────┼──────────────┘
                      ▼
              ┌──────────────┐
              │   Grafana    │
              │ (Visualization)│
              └──────────────┘
```

## Features

- **Unified Telemetry Collection**: OpenTelemetry Collector for receiving and processing metrics, logs, and traces
- **Metrics Storage**: Prometheus for time-series metrics with remote write support
- **Log Aggregation**: Loki for efficient log storage and querying
- **Distributed Tracing**: Tempo for trace storage with exemplar support
- **Visualization**: Grafana with pre-configured datasources and dashboards
- **Container-Native**: Docker Compose for local/edge deployments
- **Kubernetes-Ready**: Designed for future Helm chart and ArgoCD deployments

## Quick Start

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

### Running ObserveX

1. Clone the repository:
```bash
git clone https://github.com/brnmndl/ObserveX.git
cd ObserveX
```

2. Start the stack:
```bash
docker-compose up -d
```

3. Access the services:
- **Grafana**: http://localhost:3000 (auto-login enabled)
- **Prometheus**: http://localhost:9090
- **Loki**: http://localhost:3100
- **Tempo**: http://localhost:3200
- **OTEL Collector**: 
  - gRPC: localhost:4317
  - HTTP: localhost:4318

### Sending Telemetry Data

#### Metrics (OTLP)
```bash
# Example using OpenTelemetry SDKs
export OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
```

#### Logs (OTLP)
```bash
# Logs are sent to the same OTLP endpoint
export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT=http://localhost:4318/v1/logs
```

#### Traces (OTLP)
```bash
# Traces are sent to the same OTLP endpoint
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT=http://localhost:4318/v1/traces
```

## Configuration

### OpenTelemetry Collector
Configuration file: `config/otel-collector-config.yml`

The collector is configured with:
- OTLP receivers (gRPC and HTTP)
- Prometheus receiver for scraping
- Exporters for Prometheus, Loki, and Tempo
- Resource detection and batch processing

### Prometheus
Configuration file: `config/prometheus.yml`

Scrapes metrics from:
- Self (Prometheus)
- OpenTelemetry Collector
- Grafana, Loki, and Tempo

### Loki
Configuration file: `config/loki-config.yml`

Configured for local storage with:
- BoltDB shipper for index
- Filesystem storage for chunks
- 7-day retention policy

### Tempo
Configuration file: `config/tempo-config.yml`

Features:
- OTLP and Zipkin receivers
- Local storage backend
- Metrics generator with service graphs
- Remote write to Prometheus for RED metrics

### Grafana
Pre-configured with:
- Prometheus datasource (default)
- Loki datasource with trace correlation
- Tempo datasource with metrics and logs correlation
- Sample overview dashboard

## Management

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f otel-collector
```

### Stop the stack
```bash
docker-compose down
```

### Stop and remove volumes (clean slate)
```bash
docker-compose down -v
```

### Restart a service
```bash
docker-compose restart otel-collector
```

## Data Persistence

Data is persisted in Docker volumes:
- `prometheus-data`: Prometheus metrics
- `loki-data`: Loki logs
- `tempo-data`: Tempo traces
- `grafana-data`: Grafana dashboards and settings

## Future Roadmap

### Kubernetes Deployment
- Helm charts for easy deployment
- Values files for different environments
- Horizontal pod autoscaling support

### GitOps
- ArgoCD application manifests
- Multi-environment configurations
- Automated sync and rollback

### Additional Features
- Alert manager integration
- Custom dashboards for common use cases
- Service mesh integration
- Multi-tenancy support

## Architecture Decisions

### Why OpenTelemetry Collector?
- Vendor-neutral telemetry pipeline
- Single entry point for all observability data
- Powerful processing and routing capabilities
- Wide ecosystem support

### Why This Stack?
- **Prometheus**: Industry-standard metrics storage with excellent query language
- **Loki**: Cost-effective log aggregation from Grafana Labs
- **Tempo**: Scalable distributed tracing with exemplar support
- **Grafana**: Unified visualization platform with native support for all datasources

## Contributing

Contributions are welcome! Please open an issue or submit a pull request.

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open a GitHub issue.
