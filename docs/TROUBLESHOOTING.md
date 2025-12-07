# Troubleshooting Guide

This guide helps you diagnose and fix common issues with ObserveX.

## Service Won't Start

### Check Service Status
```bash
docker compose ps
```

### View Service Logs
```bash
# All services
docker compose logs

# Specific service
docker compose logs otel-collector
docker compose logs prometheus
docker compose logs loki
docker compose logs tempo
docker compose logs grafana
```

### Common Issues

#### Port Already in Use
**Symptom**: Error message about port binding failure

**Solution**:
1. Check what's using the port:
```bash
# On Linux/Mac
sudo lsof -i :3000  # or any other port
netstat -tulpn | grep 3000

# On Windows
netstat -ano | findstr :3000
```

2. Either stop the conflicting service or change the port in `docker-compose.yml`:
```yaml
ports:
  - "3001:3000"  # Map to different host port
```

#### Volume Permission Issues
**Symptom**: Permission denied errors in logs

**Solution**:
```bash
# Stop services
docker compose down

# Remove volumes and start fresh
docker compose down -v
docker compose up -d
```

## No Data in Grafana

### Check Datasource Configuration
1. Open Grafana: http://localhost:3000
2. Go to Configuration → Data Sources
3. Test each datasource connection
4. Check for error messages

### Verify Services Are Reachable
```bash
# From inside the network
docker compose exec grafana wget -O- http://prometheus:9090/-/healthy
docker compose exec grafana wget -O- http://loki:3100/ready
docker compose exec grafana wget -O- http://tempo:3200/ready
```

### Check if Data is Being Collected

#### Prometheus
```bash
# Check targets
open http://localhost:9090/targets

# Run a query
curl -g 'http://localhost:9090/api/v1/query?query=up'
```

#### Loki
```bash
# Check ready status
curl http://localhost:3100/ready

# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query" --data-urlencode 'query={job=~".+"}'
```

#### Tempo
```bash
# Check ready status
curl http://localhost:3200/ready
```

## OpenTelemetry Collector Issues

### Collector Not Receiving Data
**Check the collector logs**:
```bash
docker compose logs otel-collector
```

**Verify endpoints are accessible**:
```bash
# gRPC endpoint
curl -v http://localhost:4317

# HTTP endpoint
curl -v http://localhost:4318
```

**Test sending data**:
```bash
# Send test trace using curl (requires valid OTLP JSON)
curl -X POST http://localhost:4318/v1/traces \
  -H "Content-Type: application/json" \
  -d '{"resourceSpans":[]}'
```

### Collector Configuration Errors
**Validate configuration**:
```bash
# Check for YAML syntax errors
cat config/otel-collector-config.yml

# Restart collector
docker compose restart otel-collector
```

## Prometheus Issues

### No Metrics Being Scraped
**Check targets**:
1. Open http://localhost:9090/targets
2. Look for targets in "DOWN" state
3. Click on endpoint to see error

**Common causes**:
- Service not exposing metrics on expected port
- Network connectivity issues
- Authentication required

### High Memory Usage
**Solution**: Adjust retention period in `config/prometheus.yml`:
```yaml
global:
  # Add storage settings
storage:
  tsdb:
    retention.time: 7d  # Reduce from default 15d
```

## Loki Issues

### Logs Not Appearing
**Check Loki is receiving logs**:
```bash
# View Loki logs
docker compose logs loki

# Check Loki metrics
curl http://localhost:3100/metrics | grep loki_ingester_streams_created_total
```

**Verify log format**:
- Loki requires labels for indexing
- Check log timestamp is not too old (max 168h by default)

### Disk Space Issues
**Check disk usage**:
```bash
docker compose exec loki du -sh /loki/*
```

**Clean up old data**:
```bash
# Stop Loki
docker compose stop loki

# Remove volume (WARNING: deletes all logs)
docker compose down -v loki-data

# Start Loki
docker compose up -d loki
```

## Tempo Issues

### Traces Not Showing
**Check Tempo is receiving traces**:
```bash
# View Tempo logs
docker compose logs tempo

# Check Tempo metrics
curl http://localhost:3200/metrics
```

**Verify trace format**:
- Traces must be in valid OTLP format
- Check timestamp is recent

### Search Not Working
**Enable trace search in Tempo**:
Check that Tempo configuration includes search settings in `config/tempo-config.yml`.

## Grafana Issues

### Cannot Login
**Reset admin password**:
```bash
docker compose exec grafana grafana-cli admin reset-admin-password newpassword
```

Or use anonymous access (enabled by default in this setup).

### Dashboards Not Loading
**Re-provision dashboards**:
```bash
docker compose restart grafana
```

**Check provisioning logs**:
```bash
docker compose logs grafana | grep -i provision
```

## Network Issues

### Services Cannot Communicate
**Check network**:
```bash
docker network ls
docker network inspect observex_observex
```

**Verify DNS resolution**:
```bash
docker compose exec grafana ping prometheus
docker compose exec grafana ping loki
docker compose exec grafana ping tempo
```

## Performance Issues

### High CPU Usage
**Check resource usage**:
```bash
docker stats
```

**Common causes**:
- Too many metrics being collected
- High cardinality metrics
- Insufficient resources allocated to Docker

**Solutions**:
1. Reduce scrape frequency in Prometheus config
2. Add memory limits in docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
```

### Slow Query Performance
**For Prometheus**:
- Reduce query range
- Use recording rules for complex queries
- Add more memory

**For Loki**:
- Use specific label filters
- Reduce time range
- Add indices for common queries

**For Tempo**:
- Use trace ID for direct lookup
- Add proper labels for filtering
- Use shorter time ranges

## Container Issues

### Container Keeps Restarting
```bash
# Check restart count
docker compose ps

# Check exit code and error
docker compose logs --tail=50 <service-name>

# Check resource constraints
docker stats
```

### Container Out of Memory
**Increase memory limits**:
```yaml
deploy:
  resources:
    limits:
      memory: 2G
```

## Getting Help

If you're still experiencing issues:

1. Check the logs of all services
2. Verify your configuration files
3. Search existing GitHub issues
4. Create a new issue with:
   - Description of the problem
   - Steps to reproduce
   - Relevant logs
   - Your environment (OS, Docker version, etc.)

## Useful Commands

```bash
# View all service logs
make logs

# Check service status
make status

# Restart everything
make restart

# Clean slate (WARNING: deletes all data)
make clean
make up

# Validate configuration
make validate

# Check Docker resources
docker system df

# Clean up Docker resources
docker system prune -a
```
