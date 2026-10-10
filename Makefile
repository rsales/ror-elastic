.PHONY: help setup up down logs health elastic kibana \
        install install-backend install-frontend \
        backend frontend test test-backend \
        sync sync-reset index-info api-smoke

PAGES ?= 25
API_URL ?= http://localhost:3000

.DEFAULT_GOAL := help

help: ## List local development commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-18s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: up install ## Start Elasticsearch/Kibana and install app dependencies

up: ## Start Elasticsearch and Kibana
	docker compose up -d

down: ## Stop containers (preserves the Elasticsearch data volume)
	docker compose down

logs: ## Follow Docker Compose logs
	docker compose logs -f

health: ## Check Elasticsearch health
	curl --silent --show-error --fail http://localhost:9200/_cluster/health

elastic: ## Open Elasticsearch in the browser (macOS)
	open http://localhost:9200

kibana: ## Open Kibana in the browser (macOS)
	open http://localhost:5601

install: install-backend install-frontend ## Install Rails and Nuxt dependencies

install-backend: ## Install Rails dependencies
	cd backend && bundle install

install-frontend: ## Install Nuxt dependencies
	cd frontend && pnpm install

backend: ## Start the Rails API
	cd backend && bin/rails server

frontend: ## Start the Nuxt dev server
	cd frontend && pnpm dev --port 3001

test: test-backend ## Run backend test suite

test-backend: ## Run Rails/Minitest tests
	cd backend && bin/rails test

sync: ## Ingest/update TMDB movies without resetting the index
	cd backend && TMDB_SYNC_PAGES=$(PAGES) bin/rails runner 'Tmdb::SyncMoviesService.new.call'

sync-reset: ## Recreate the index, then ingest TMDB movies (requires CONFIRM_RESET=1)
	@test "$(CONFIRM_RESET)" = "1" || (echo "This deletes and recreates the Elasticsearch index. Run: make sync-reset CONFIRM_RESET=1 PAGES=$(PAGES)" >&2; exit 1)
	cd backend && TMDB_SYNC_PAGES=$(PAGES) bin/rails runner 'Tmdb::SyncMoviesService.new(reset_index: true).call'

index-info: ## Show indexed movie document count and index metadata
	curl --silent --show-error --fail http://localhost:9200/_cat/indices/movies?v

api-smoke: ## Check health, search, and suggestions (Rails API must be running)
	@set -e; \
	echo "== Health =="; curl --silent --show-error --fail "$(API_URL)/api/health"; echo; \
	echo "== Search =="; curl --silent --show-error --fail "$(API_URL)/api/search?size=5"; echo; \
	echo "== Suggestions =="; curl --silent --show-error --fail "$(API_URL)/api/suggest?q=spi"; echo
