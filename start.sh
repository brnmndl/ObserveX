#!/bin/bash

# ObserveX Quick Start Script
# This script helps you get started with ObserveX quickly

set -e

echo "======================================"
echo "     ObserveX Quick Start"
echo "======================================"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose is not available"
    echo "Please install Docker Compose v2 or upgrade Docker Desktop"
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"
echo ""

# Validate docker-compose.yml
echo "📋 Validating configuration..."
if docker compose config --quiet; then
    echo "✅ Configuration is valid"
else
    echo "❌ Configuration validation failed"
    exit 1
fi
echo ""

# Pull images
echo "📥 Pulling Docker images (this may take a few minutes)..."
docker compose pull
echo ""

# Start services
echo "🚀 Starting ObserveX services..."
docker compose up -d
echo ""

# Wait for services to be ready
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check service status
echo ""
echo "📊 Service Status:"
docker compose ps
echo ""

# Display access information
echo "======================================"
echo "     ObserveX is Ready!"
echo "======================================"
echo ""
echo "Access the following services:"
echo ""
echo "🎨 Grafana (Visualization)"
echo "   → http://localhost:3000"
echo "   (Auto-login enabled - no credentials needed)"
echo ""
echo "📊 Prometheus (Metrics)"
echo "   → http://localhost:9090"
echo ""
echo "📝 Loki (Logs)"
echo "   → http://localhost:3100"
echo ""
echo "🔍 Tempo (Traces)"
echo "   → http://localhost:3200"
echo ""
echo "📡 OpenTelemetry Collector"
echo "   → gRPC: localhost:4317"
echo "   → HTTP: localhost:4318"
echo ""
echo "======================================"
echo "Next Steps:"
echo "======================================"
echo ""
echo "1. Open Grafana at http://localhost:3000"
echo "2. Explore the pre-configured datasources"
echo "3. Check out the sample dashboard"
echo "4. Send telemetry data to http://localhost:4318"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop:      docker compose down"
echo "To clean up:  docker compose down -v"
echo ""
echo "For more information, see README.md"
echo ""
