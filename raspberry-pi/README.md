# Raspberry Pi Node Exporter Setup

This directory contains the configuration to run Prometheus Node Exporter on a Raspberry Pi with custom metrics collection including throttling status, CPU temperature, voltage, and frequency.

## Features

- **Standard Node Exporter Metrics**: CPU usage, memory usage, disk I/O, network stats, etc.
- **Raspberry Pi Specific Metrics**:
  - Throttling status (`vcgencmd get_throttled`)
  - CPU temperature
  - CPU voltage
  - CPU frequency
  - Detailed throttling flags (under-voltage, frequency capping, thermal throttling)

## Files

- `docker-compose.yml` - Docker Compose configuration for Node Exporter
- `collect_rpi_metrics.sh` - Script to collect Raspberry Pi specific metrics
- `setup.sh` - Automated setup script
- `textfile-collector/` - Directory where custom metrics are stored (created during setup)

## Installation

### Prerequisites

- Docker and Docker Compose installed on your Raspberry Pi
- Access to `vcgencmd` (pre-installed on Raspberry Pi OS)
- User must be in `video` group to access `vcgencmd`

### Quick Start

1. Copy this directory to your Raspberry Pi:
   ```bash
   scp -r raspberry-pi pi@raspberrypi.local:~/observex/
   ```

2. SSH into your Raspberry Pi:
   ```bash
   ssh pi@raspberrypi.local
   cd ~/observex/raspberry-pi
   ```

3. Run the setup script:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

4. Start Node Exporter:
   ```bash
   docker-compose up -d
   ```

5. Verify it's working:
   ```bash
   curl http://localhost:9100/metrics | grep rpi_
   ```

## Manual Setup

If you prefer to set up manually:

1. Make the collection script executable:
   ```bash
   chmod +x collect_rpi_metrics.sh
   ```

2. Update the path in `collect_rpi_metrics.sh` to match your installation directory

3. Create the textfile-collector directory:
   ```bash
   mkdir -p textfile-collector
   ```

4. Test the metrics collection:
   ```bash
   ./collect_rpi_metrics.sh
   cat textfile-collector/rpi_metrics.prom
   ```

5. Add to crontab to run every minute:
   ```bash
   crontab -e
   ```
   Add this line:
   ```
   * * * * * /path/to/collect_rpi_metrics.sh
   ```

6. Start Node Exporter:
   ```bash
   docker-compose up -d
   ```

## Custom Metrics

The following custom metrics are collected:

### Throttling Status
- `rpi_throttled` - Raw throttling hex value as decimal
- `rpi_throttled_under_voltage` - Currently under-voltage (0 or 1)
- `rpi_throttled_freq_capped` - Currently frequency capped (0 or 1)
- `rpi_throttled_currently_throttled` - Currently throttled (0 or 1)
- `rpi_throttled_soft_temp_limit` - Soft temperature limit active (0 or 1)
- `rpi_throttled_under_voltage_occurred` - Under-voltage has occurred since boot (0 or 1)
- `rpi_throttled_freq_capped_occurred` - Frequency capping has occurred (0 or 1)
- `rpi_throttled_throttled_occurred` - Throttling has occurred (0 or 1)
- `rpi_throttled_soft_temp_limit_occurred` - Soft temp limit has occurred (0 or 1)

### Other Metrics
- `rpi_cpu_temperature_celsius` - CPU temperature in Celsius
- `rpi_cpu_voltage_volts` - CPU voltage in volts
- `rpi_cpu_frequency_mhz` - CPU frequency in MHz
- `rpi_metrics_collection_timestamp_seconds` - Timestamp of last collection

### Standard Node Exporter Metrics
- CPU usage: `node_cpu_seconds_total`
- Memory usage: `node_memory_*`
- Disk usage: `node_filesystem_*`
- Network stats: `node_network_*`
- And many more...

## Accessing Metrics

### Local Access
```bash
curl http://localhost:9100/metrics
```

### From Prometheus Server
Add this job to your Prometheus configuration:

```yaml
scrape_configs:
  - job_name: 'raspberry-pi'
    static_configs:
      - targets: ['<raspberry-pi-ip>:9100']
        labels:
          instance: 'raspberry-pi'
          environment: 'home'
```

## Prometheus Queries

Example queries for Grafana or PromQL:

### CPU Usage
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Memory Usage Percentage
```promql
100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))
```

### Check if Currently Throttled
```promql
rpi_throttled_currently_throttled
```

### CPU Temperature
```promql
rpi_cpu_temperature_celsius
```

### Under-voltage Alert
```promql
rpi_throttled_under_voltage > 0
```

## Troubleshooting

### Metrics not appearing
1. Check if the collection script is running:
   ```bash
   ./collect_rpi_metrics.sh
   cat textfile-collector/rpi_metrics.prom
   ```

2. Check cron logs:
   ```bash
   grep CRON /var/log/syslog
   ```

3. Verify Node Exporter container is running:
   ```bash
   docker-compose ps
   docker-compose logs
   ```

### vcgencmd not found
- Ensure you're running on a Raspberry Pi with Raspberry Pi OS
- Add user to video group: `sudo usermod -a -G video $USER`
- Log out and back in

### Permission denied
- Make sure scripts are executable: `chmod +x *.sh`
- Check file ownership and permissions

## Stopping and Removing

Stop Node Exporter:
```bash
docker-compose down
```

Remove cron job:
```bash
crontab -e
# Delete the line containing 'collect_rpi_metrics.sh'
```

## Notes

- The metrics collection script runs every minute via cron
- Metrics are written atomically to avoid partial reads
- The textfile collector directory is mounted read-only in the container
- Network mode is set to `host` for better performance and simpler networking

## Integration with Main Prometheus

Update your main Prometheus configuration ([prometheus/prometheus.yml](../prometheus/prometheus.yml)) to scrape this Raspberry Pi:

```yaml
scrape_configs:
  - job_name: 'node-exporter-rpi'
    static_configs:
      - targets: ['<raspberry-pi-ip>:9100']
```

Then restart Prometheus:
```bash
cd ../prometheus
docker-compose restart
```
