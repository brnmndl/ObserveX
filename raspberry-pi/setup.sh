#!/bin/bash

# Setup script for Raspberry Pi Node Exporter with custom metrics
# Run this script on your Raspberry Pi

echo "Setting up Raspberry Pi Node Exporter..."

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Make the metrics collection script executable
chmod +x "$SCRIPT_DIR/collect_rpi_metrics.sh"

# Update the path in the collection script to use the current directory
sed -i "s|/Users/barunm/Repos/ObserveX/raspberry-pi|$SCRIPT_DIR|g" "$SCRIPT_DIR/collect_rpi_metrics.sh"

# Create textfile-collector directory
mkdir -p "$SCRIPT_DIR/textfile-collector"

# Run the metrics collection script once to test
echo "Testing metrics collection..."
"$SCRIPT_DIR/collect_rpi_metrics.sh"

if [ -f "$SCRIPT_DIR/textfile-collector/rpi_metrics.prom" ]; then
    echo "✓ Metrics collection test successful!"
    cat "$SCRIPT_DIR/textfile-collector/rpi_metrics.prom"
else
    echo "✗ Metrics collection failed!"
    exit 1
fi

# Setup cron job to run every minute
CRON_JOB="* * * * * $SCRIPT_DIR/collect_rpi_metrics.sh"

# Check if cron job already exists
if crontab -l 2>/dev/null | grep -q "collect_rpi_metrics.sh"; then
    echo "Cron job already exists"
else
    # Add cron job
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✓ Cron job added to run metrics collection every minute"
fi

echo ""
echo "Setup complete! Next steps:"
echo "1. Start Node Exporter: docker-compose up -d"
echo "2. Verify Node Exporter is running: curl http://localhost:9100/metrics"
echo "3. Check custom metrics: curl http://localhost:9100/metrics | grep rpi_"
echo ""
echo "To remove the cron job later:"
echo "  crontab -e  # then delete the line containing 'collect_rpi_metrics.sh'"
