#!/bin/bash

# Raspberry Pi Metrics Collector for Prometheus Node Exporter
# This script collects Raspberry Pi specific metrics and exports them in Prometheus format

TEXTFILE_COLLECTOR_DIR="/Users/barunm/Repos/ObserveX/raspberry-pi/textfile-collector"
PROM_FILE="$TEXTFILE_COLLECTOR_DIR/rpi_metrics.prom"
TEMP_FILE="$PROM_FILE.$$"

mkdir -p "$TEXTFILE_COLLECTOR_DIR"

# Start collecting metrics
{
    echo "# HELP rpi_throttled Raspberry Pi throttling status (hex value)"
    echo "# TYPE rpi_throttled gauge"
    
    # Get throttled status
    if command -v vcgencmd &> /dev/null; then
        THROTTLED=$(vcgencmd get_throttled | cut -d= -f2)
        # Convert hex to decimal for Prometheus
        THROTTLED_DEC=$((16#${THROTTLED#0x}))
        echo "rpi_throttled $THROTTLED_DEC"
        
        # Decode throttle bits for easier monitoring
        echo "# HELP rpi_throttled_under_voltage Currently under-voltage"
        echo "# TYPE rpi_throttled_under_voltage gauge"
        echo "rpi_throttled_under_voltage $(( ($THROTTLED_DEC & 0x1) > 0 ))"
        
        echo "# HELP rpi_throttled_freq_capped Currently frequency capped"
        echo "# TYPE rpi_throttled_freq_capped gauge"
        echo "rpi_throttled_freq_capped $(( ($THROTTLED_DEC & 0x2) > 0 ))"
        
        echo "# HELP rpi_throttled_currently_throttled Currently throttled"
        echo "# TYPE rpi_throttled_currently_throttled gauge"
        echo "rpi_throttled_currently_throttled $(( ($THROTTLED_DEC & 0x4) > 0 ))"
        
        echo "# HELP rpi_throttled_soft_temp_limit Currently soft temperature limit active"
        echo "# TYPE rpi_throttled_soft_temp_limit gauge"
        echo "rpi_throttled_soft_temp_limit $(( ($THROTTLED_DEC & 0x8) > 0 ))"
        
        echo "# HELP rpi_throttled_under_voltage_occurred Under-voltage has occurred"
        echo "# TYPE rpi_throttled_under_voltage_occurred gauge"
        echo "rpi_throttled_under_voltage_occurred $(( ($THROTTLED_DEC & 0x10000) > 0 ))"
        
        echo "# HELP rpi_throttled_freq_capped_occurred Frequency capping has occurred"
        echo "# TYPE rpi_throttled_freq_capped_occurred gauge"
        echo "rpi_throttled_freq_capped_occurred $(( ($THROTTLED_DEC & 0x20000) > 0 ))"
        
        echo "# HELP rpi_throttled_throttled_occurred Throttling has occurred"
        echo "# TYPE rpi_throttled_throttled_occurred gauge"
        echo "rpi_throttled_throttled_occurred $(( ($THROTTLED_DEC & 0x40000) > 0 ))"
        
        echo "# HELP rpi_throttled_soft_temp_limit_occurred Soft temperature limit has occurred"
        echo "# TYPE rpi_throttled_soft_temp_limit_occurred gauge"
        echo "rpi_throttled_soft_temp_limit_occurred $(( ($THROTTLED_DEC & 0x80000) > 0 ))"
    fi
    
    # Get CPU temperature
    if command -v vcgencmd &> /dev/null; then
        TEMP=$(vcgencmd measure_temp | cut -d= -f2 | cut -d\' -f1)
        echo "# HELP rpi_cpu_temperature_celsius CPU temperature in Celsius"
        echo "# TYPE rpi_cpu_temperature_celsius gauge"
        echo "rpi_cpu_temperature_celsius $TEMP"
    fi
    
    # Get CPU voltage
    if command -v vcgencmd &> /dev/null; then
        VOLTAGE=$(vcgencmd measure_volts core | cut -d= -f2 | sed 's/V//')
        echo "# HELP rpi_cpu_voltage_volts CPU voltage in volts"
        echo "# TYPE rpi_cpu_voltage_volts gauge"
        echo "rpi_cpu_voltage_volts $VOLTAGE"
    fi
    
    # Get CPU frequency
    if command -v vcgencmd &> /dev/null; then
        FREQ=$(vcgencmd measure_clock arm | cut -d= -f2)
        FREQ_MHZ=$(echo "scale=2; $FREQ / 1000000" | bc)
        echo "# HELP rpi_cpu_frequency_mhz CPU frequency in MHz"
        echo "# TYPE rpi_cpu_frequency_mhz gauge"
        echo "rpi_cpu_frequency_mhz $FREQ_MHZ"
    fi
    
    echo "# HELP rpi_metrics_collection_timestamp_seconds Timestamp of metrics collection"
    echo "# TYPE rpi_metrics_collection_timestamp_seconds gauge"
    echo "rpi_metrics_collection_timestamp_seconds $(date +%s)"
    
} > "$TEMP_FILE"

# Atomically replace the metrics file
mv "$TEMP_FILE" "$PROM_FILE"
