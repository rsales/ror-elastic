SHELL := /bin/bash
.DEFAULT_GOAL := help

PAGES ?=
ES_URL ?= http://localhost:9200
API_URL ?= http://localhost:3000
INDEX ?= movies

.PHONY: help setup up down logs wait-es health elastic kibana \
        install install-backend install-frontend \
        ingest ingest-reset sync sync-reset test test-backend build verify \
        backend frontend index-info api-smoke smoke

help: ## List available local development commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: up wait-es install ## Start infrastructure, wait for Elasticsearch, and install dependencies

up: ## Start Elasticsearch and Kibana
	docker compose up -d

down: ## Stop containers without deleting the Elasticsearch data volume
	docker compose down

logs: ## Follow Elasticsearch and Kibana logs
	docker compose logs -f

wait-es: ## Wait until Elasticsearch responds
	@echo "Waiting for Elasticsearch at $(ES_URL)..."
	@for attempt in $$(seq 1 60); do \
		if curl --silent --fail "$(ES_URL)/_cluster/health" >/dev/null 2>&1; then \
			echo "Elasticsearch is ready."; exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo "Elasticsearch did not become ready within 120 seconds." >&2; exit 1

health: ## Print Elasticsearch cluster health
	curl --silent --show-error --fail "$(ES_URL)/_cluster/health"

elastic: ## Open Elasticsearch in the browser (macOS)
	open "$(ES_URL)"

kibana: ## Open Kibana in the browser (macOS)
	open http://localhost:5601

install: install-backend install-frontend ## Install Rails and Nuxt dependencies

install-backend: ## Install Rails backend dependencies
	cd backend && bundle install

install-frontend: ## Install Nuxt frontend dependencies
	cd frontend && pnpm install

ingest: sync ## Ingest/update TMDB movies without deleting the index (alias for sync)

sync: wait-es ## Rails-native alias for ingest
	cd backend && $(if $(PAGES),TMDB_SYNC_PAGES=$(PAGES) )bin/rails runner 'Tmdb::SyncMoviesService.new.call'

ingest-reset: sync-reset ## Recreate the index and ingest data (requires CONFIRM_RESET=1)

sync-reset: wait-es ## Rails-native reset command (requires CONFIRM_RESET=1)
	@test "$(CONFIRM_RESET)" = "1" || (echo "Destructive: this recreates the configured Elasticsearch index. Run: make ingest-reset CONFIRM_RESET=1 PAGES=$(PAGES)" >&2; exit 1)
	cd backend && $(if $(PAGES),TMDB_SYNC_PAGES=$(PAGES) )bin/rails runner 'Tmdb::SyncMoviesService.new(reset_index: true).call'

test: test-backend ## Run all currently configured automated tests

test-backend: ## Run Rails/Minitest contract tests
	cd backend && bin/rails test

build: ## Build the Nuxt frontend for production
	cd frontend && pnpm build

verify: test build ## Run backend tests and build the frontend

backend: ## Start the Rails API
	cd backend && bin/rails server

frontend: ## Start the Nuxt development server
	cd frontend && pnpm dev --port 3001

index-info: ## Show Elasticsearch metadata for the movies index
	curl --silent --show-error --fail "$(ES_URL)/_cat/indices/$(INDEX)?v"

api-smoke: ## Check health, search, and suggestions (Rails API must be running)
	@set -e; \
	echo "== Backend health =="; curl --silent --show-error --fail "$(API_URL)/api/health"; echo; \
	echo "== Browse search =="; curl --silent --show-error --fail "$(API_URL)/api/search?size=5"; echo; \
	echo "== Suggestions =="; curl --silent --show-error --fail "$(API_URL)/api/suggest?q=spi"; echo

smoke: api-smoke ## Alias for api-smoke
