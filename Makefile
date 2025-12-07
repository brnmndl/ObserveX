.PHONY: help up down restart logs status clean validate pull

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

restart: ## Restart all services
	docker compose restart

logs: ## View logs from all services
	docker compose logs -f

status: ## Show status of all services
	docker compose ps

clean: ## Stop services and remove volumes (WARNING: deletes all data)
	docker compose down -v

validate: ## Validate docker-compose.yml
	docker compose config --quiet

pull: ## Pull latest images
	docker compose pull

grafana-logs: ## View Grafana logs
	docker compose logs -f grafana

otel-logs: ## View OpenTelemetry Collector logs
	docker compose logs -f otel-collector

prometheus-logs: ## View Prometheus logs
	docker compose logs -f prometheus

loki-logs: ## View Loki logs
	docker compose logs -f loki

tempo-logs: ## View Tempo logs
	docker compose logs -f tempo
