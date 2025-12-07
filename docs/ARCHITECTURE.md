# ObserveX Architecture

This document describes the architecture and design decisions for ObserveX.

## Overview

ObserveX is a container-native observability platform that provides a unified solution for metrics, logs, and traces. It's built on industry-standard open-source components and designed to be simple to deploy while remaining powerful and scalable.

## Core Components

### 1. OpenTelemetry Collector
**Role**: Central telemetry pipeline

The OpenTelemetry Collector acts as the single entry point for all observability data. It receives telemetry in multiple formats (primarily OTLP) and routes it to the appropriate backend systems.

**Key Features**:
- **Receivers**: Accept telemetry data in OTLP format (gRPC and HTTP)
- **Processors**: Transform, filter, and enrich telemetry data
- **Exporters**: Send data to Prometheus, Loki, and Tempo
- **Resource Detection**: Automatically detect environment metadata

**Configuration**: `config/otel-collector-config.yml`

**Ports**:
- 4317: OTLP gRPC receiver
- 4318: OTLP HTTP receiver
- 8888: Prometheus metrics (collector's own metrics)
- 8889: Prometheus exporter (application metrics)
- 13133: Health check endpoint

### 2. Prometheus
**Role**: Metrics storage and querying

Prometheus stores time-series metrics and provides a powerful query language (PromQL) for analyzing them.

**Key Features**:
- Remote write receiver enabled (for OTEL Collector)
- Scrapes metrics from all ObserveX components
- TSDB storage with configurable retention
- Alert manager ready (not included in base setup)

**Configuration**: `config/prometheus.yml`

**Port**: 9090

**Data Flow**:
```
Application → OTEL Collector → Prometheus (Remote Write)
Prometheus → Prometheus (Scrape own metrics)
Prometheus → Grafana (Query)
```

### 3. Loki
**Role**: Log aggregation and storage

Loki stores logs efficiently using a unique indexing approach that only indexes metadata (labels), not log content.

**Key Features**:
- BoltDB-Shipper for index storage
- Filesystem backend for chunks
- Label-based indexing
- LogQL query language
- 7-day retention by default

**Configuration**: `config/loki-config.yml`

**Port**: 3100

**Data Flow**:
```
Application → OTEL Collector → Loki (Push)
Loki → Grafana (Query via LogQL)
```

### 4. Tempo
**Role**: Distributed tracing backend

Tempo stores traces efficiently with support for trace correlation with metrics and logs.

**Key Features**:
- OTLP and Zipkin receivers
- Local storage backend (filesystem)
- Metrics generator for RED metrics
- Service graph generation
- Exemplar support

**Configuration**: `config/tempo-config.yml`

**Ports**:
- 3200: Tempo HTTP API
- 4316: OTLP gRPC (mapped to avoid conflict with collector)
- 9411: Zipkin receiver

**Data Flow**:
```
Application → OTEL Collector → Tempo (OTLP)
Application → Tempo (Direct, optional)
Tempo → Prometheus (Metrics via remote write)
Tempo → Grafana (Query)
```

### 5. Grafana
**Role**: Unified visualization platform

Grafana provides a single pane of glass for all observability data.

**Key Features**:
- Pre-configured datasources (Prometheus, Loki, Tempo)
- Automatic datasource provisioning
- Dashboard provisioning support
- Trace to logs correlation
- Trace to metrics correlation
- Anonymous access enabled for easy development

**Configuration**: `config/grafana/provisioning/`

**Port**: 3000

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                 Instrumented Applications                    │
│         (OpenTelemetry SDKs or Manual Instrumentation)       │
└───────────┬──────────────┬──────────────┬───────────────────┘
            │              │              │
            │ Metrics      │ Logs         │ Traces
            │ (OTLP)       │ (OTLP)       │ (OTLP)
            │              │              │
            v              v              v
┌────────────────────────────────────────────────────────────┐
│           OpenTelemetry Collector                          │
│                                                            │
│  ┌──────────────────────────────────────────────────┐    │
│  │ Receivers (OTLP gRPC/HTTP, Prometheus)           │    │
│  └──────────────┬───────────────────────────────────┘    │
│                 v                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │ Processors (Batch, Memory Limiter, Resource Det.)│    │
│  └──────────────┬───────────────────────────────────┘    │
│                 v                                          │
│  ┌──────────────────────────────────────────────────┐    │
│  │ Exporters (Prom, Loki, Tempo)                    │    │
│  └──────┬──────────────┬──────────────┬─────────────┘    │
└─────────┼──────────────┼──────────────┼──────────────────┘
          │              │              │
          │ Remote Write │ Push         │ OTLP
          v              v              v
┌──────────────┐  ┌────────────┐  ┌────────────┐
│  Prometheus  │  │    Loki    │  │   Tempo    │
│              │  │            │  │            │
│  - PromQL    │  │  - LogQL   │  │  - TraceQL │
│  - TSDB      │  │  - Index   │  │  - Blocks  │
│  - Alerts    │  │  - Chunks  │  │  - WAL     │
└──────┬───────┘  └─────┬──────┘  └─────┬──────┘
       │                │                │
       │ Query          │ Query          │ Query
       └────────────────┼────────────────┘
                        v
                ┌──────────────┐
                │   Grafana    │
                │              │
                │  - Dashboards│
                │  - Explore   │
                │  - Alerts    │
                └──────────────┘
```

## Network Architecture

All services run in a dedicated Docker network (`observex`) which provides:
- Service discovery via DNS
- Network isolation
- Easy service-to-service communication

**Service Communication**:
- Grafana → Prometheus: HTTP on port 9090
- Grafana → Loki: HTTP on port 3100
- Grafana → Tempo: HTTP on port 3200
- OTEL Collector → Prometheus: HTTP on port 9090 (remote write)
- OTEL Collector → Loki: HTTP on port 3100 (push)
- OTEL Collector → Tempo: gRPC on port 4317
- Tempo → Prometheus: HTTP on port 9090 (metrics generator remote write)
- Prometheus → Services: HTTP scraping on various ports

## Storage Architecture

### Volumes
ObserveX uses named Docker volumes for persistent storage:

```
prometheus-data/  → Prometheus TSDB
loki-data/        → Loki chunks and index
tempo-data/       → Tempo blocks and WAL
grafana-data/     → Grafana dashboards and settings
```

### Data Retention
- **Prometheus**: Default 15 days (configurable)
- **Loki**: 7 days (configured in loki-config.yml)
- **Tempo**: 1 hour for blocks (configured for development)
- **Grafana**: Indefinite (dashboard and config persistence)

## Scalability Considerations

### Current Architecture (Docker Compose)
- **Target**: Development, edge deployments, small production
- **Limits**: Single-node, limited by host resources
- **Strengths**: Simple, fast deployment, easy debugging

### Future Architecture (Kubernetes)
Planned enhancements for Kubernetes deployment:

1. **Horizontal Scaling**:
   - Multiple OTEL Collector replicas
   - Distributed Tempo deployment
   - Loki distributed mode
   - Prometheus federation

2. **High Availability**:
   - Redundant collectors
   - Prometheus HA pairs
   - Loki replication
   - Tempo replication

3. **Storage**:
   - S3-compatible object storage for Loki
   - S3-compatible object storage for Tempo
   - Persistent volumes for Prometheus

## Security Considerations

### Current Implementation
- **Authentication**: Disabled for development (Grafana anonymous access)
- **Encryption**: No TLS (all HTTP communication)
- **Network**: Isolated Docker network
- **Exposure**: Only necessary ports exposed to host

### Production Recommendations
1. Enable authentication on all services
2. Use TLS for all communication
3. Implement network policies
4. Use secrets management (HashiCorp Vault, Kubernetes Secrets)
5. Enable RBAC in Grafana
6. Implement rate limiting
7. Regular security updates

## Monitoring the Monitor

ObserveX monitors itself:
- Prometheus scrapes metrics from all components
- Logs from all services are available via `docker compose logs`
- Health checks enabled on all services
- Service metrics exposed and scraped

**Self-monitoring endpoints**:
- OTEL Collector: http://localhost:8888/metrics
- Prometheus: http://localhost:9090/metrics
- Loki: http://localhost:3100/metrics
- Tempo: http://localhost:3200/metrics
- Grafana: http://localhost:3000/metrics

## Design Decisions

### Why OpenTelemetry Collector?
- **Vendor Neutrality**: Not tied to any specific vendor
- **Flexibility**: Supports multiple protocols and formats
- **Future-proof**: Industry standard with wide adoption
- **Single Entry Point**: Simplifies application integration

### Why This Stack?
- **Prometheus**: Industry standard for metrics, excellent ecosystem
- **Loki**: Cost-effective, integrates well with Grafana
- **Tempo**: Native Grafana Labs product, excellent correlation features
- **Grafana**: Best-in-class visualization, native support for all backends

### Configuration Management
- **Files over env vars**: More maintainable, easier to version control
- **Provisioning**: Automated datasource and dashboard setup
- **Minimal defaults**: Sane defaults that work out of the box

### Docker Compose vs. Kubernetes
**Docker Compose** (current):
- Faster to get started
- Easier to debug
- Good for development and edge
- Lower resource requirements

**Kubernetes** (future):
- Better for production at scale
- More operational complexity
- Better for multi-tenant scenarios
- Cloud-native tooling

## Extension Points

The architecture is designed to be extensible:

1. **Additional Receivers**: Add Jaeger, Zipkin, etc. to OTEL Collector
2. **Additional Exporters**: Send data to cloud services
3. **Processors**: Add custom processing logic
4. **Dashboards**: Easy to add via provisioning
5. **Alert Rules**: Can add to Prometheus and Grafana
6. **Alert Manager**: Can be added alongside Prometheus

## Performance Characteristics

### Expected Throughput
- **Metrics**: 100K+ samples/second (depends on cardinality)
- **Logs**: 10K+ lines/second (depends on log size)
- **Traces**: 1K+ spans/second (depends on span complexity)

### Resource Requirements
**Minimum** (development):
- CPU: 2 cores
- Memory: 4GB
- Disk: 10GB

**Recommended** (production):
- CPU: 4+ cores
- Memory: 8GB+
- Disk: 50GB+ (depends on retention)

## Future Enhancements

### Short Term
- Alert Manager integration
- More example dashboards
- Sample application instrumentation examples
- Health check improvements

### Medium Term
- Helm charts for Kubernetes deployment
- ArgoCD application manifests
- Multi-environment support
- Resource limit tuning

### Long Term
- Multi-tenancy support
- Horizontal scaling
- Cloud provider integrations
- Service mesh integration (Istio, Linkerd)
- Advanced correlation features
