# Helm Chart (Future)

This directory will contain the Helm chart for deploying ObserveX on Kubernetes.

## Planned Structure

```
helm/
├── Chart.yaml
├── values.yaml
├── values-dev.yaml
├── values-prod.yaml
└── templates/
    ├── otel-collector/
    ├── prometheus/
    ├── loki/
    ├── tempo/
    └── grafana/
```

## Features (Planned)

- Customizable resource limits
- Horizontal Pod Autoscaling
- Persistent volume claims
- Service mesh integration
- Multi-environment support
- High availability configurations
