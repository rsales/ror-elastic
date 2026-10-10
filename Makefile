SHELL := /bin/bash
.DEFAULT_GOAL := help

PAGES ?=
ES_URL ?= http://localhost:9200
API_URL ?= http://localhost:3000
INDEX ?= movies

.PHONY: help setup setup-env setup-backend setup-ingestion setup-frontend db-setup ruby-check \
        up down logs wait-es health elastic kibana \
        install install-backend install-ingestion install-frontend \
        ingest ingest-reset sync sync-reset test test-backend build verify \
        backend frontend index-info api-smoke smoke

help: ## List available local development commands
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Create env files, start Elasticsearch, install backend/frontend, prepare DB
	$(MAKE) setup-env
	$(MAKE) up
	$(MAKE) wait-es
	$(MAKE) setup-backend
	$(MAKE) setup-frontend

setup-env: ## Create the Rails env file from the example without overwriting it
	@test -f backend/.env || cp backend/.env.example backend/.env
	@echo "Environment file ready. Add TMDB_API_KEY to backend/.env before syncing TMDB data."

setup-backend: ## Install Ruby gems and prepare the Rails database
	$(MAKE) setup-env
	$(MAKE) install-backend
	$(MAKE) db-setup

setup-ingestion: install-ingestion ## Rails TMDB ingestion is provided by the backend service

setup-frontend: ## Install Nuxt dependencies
	$(MAKE) install-frontend

db-setup: ## Create the database and run pending migrations
	cd backend && bin/rails db:prepare

up: ## Start Elasticsearch and Kibana
	docker compose up -d

down: ## Stop containers without deleting the Elasticsearch data volume
	docker compose down

logs: ## Follow Docker Compose logs
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

install: install-backend install-frontend ## Install backend and frontend dependencies

install-backend: ruby-check ## Install Rails gem dependencies
	cd backend && bundle install

install-ingestion: install-backend ## Rails ingestion dependencies are part of the backend bundle

ruby-check: ## Check the Ruby version required by backend/.ruby-version
	@required="$$(cat backend/.ruby-version)"; actual="$$(cd backend && ruby -e 'print RUBY_VERSION' 2>/dev/null || true)"; \
	if [ "$$actual" != "$$required" ]; then \
		echo "Ruby $$required is required (active version: $$actual)." >&2; \
		echo "With rbenv, run: rbenv install $$required" >&2; exit 1; \
	fi

install-frontend: ## Install Nuxt dependencies
	cd frontend && pnpm install

ingest: sync ## Ingest/update TMDB movies without resetting the index

sync: wait-es ## Rails-native sync command; PAGES overrides TMDB_SYNC_PAGES in .env
	cd backend && $(if $(PAGES),TMDB_SYNC_PAGES=$(PAGES) )bin/rails runner 'Tmdb::SyncMoviesService.new.call'

ingest-reset: sync-reset ## Recreate the index and ingest data (requires CONFIRM_RESET=1)

sync-reset: wait-es ## Rails-native reset command (requires CONFIRM_RESET=1)
	@test "$(CONFIRM_RESET)" = "1" || (echo "Destructive: this recreates the configured Elasticsearch index. Run: make ingest-reset CONFIRM_RESET=1 [PAGES=25]" >&2; exit 1)
	cd backend && $(if $(PAGES),TMDB_SYNC_PAGES=$(PAGES) )bin/rails runner 'Tmdb::SyncMoviesService.new(reset_index: true).call'

test: test-backend ## Run all configured backend tests

test-backend: ## Run Rails/Minitest contract tests
	cd backend && bin/rails test

build: ## Build the Nuxt frontend for production
	cd frontend && pnpm build

verify: test build ## Run backend tests and build the frontend

backend: ## Start the Rails API
	cd backend && bin/rails server

frontend: ## Start the Nuxt development server
	cd frontend && pnpm dev --port 3001

index-info: ## Show Elasticsearch metadata for the configured index
	curl --silent --show-error --fail "$(ES_URL)/_cat/indices/$(INDEX)?v"

api-smoke: ## Check health, search, and suggestions (Rails API must be running)
	@set -e; \
	echo "== Backend health =="; curl --silent --show-error --fail "$(API_URL)/api/health"; echo; \
	echo "== Browse search =="; curl --silent --show-error --fail "$(API_URL)/api/search?size=5"; echo; \
	echo "== Suggestions =="; curl --silent --show-error --fail "$(API_URL)/api/suggest?q=spi"; echo

smoke: api-smoke ## Alias for api-smoke
