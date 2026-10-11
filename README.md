# ROR Elastic — Movie Search POC

A full-stack movie-search proof of concept using **Ruby on Rails 8**, **Elasticsearch 8**, and a **Nuxt 4 frontend**. Movie metadata is sourced from TMDB.

This is the Rails implementation of the search experiments being compared with [poc-elastic](https://github.com/rsales/poc-elastic). Both POCs share behavioral scenarios in `contracts/search-cases.json`; each keeps the response envelope required by its existing frontend.

## Capabilities

- TMDB ingestion and Elasticsearch document mapping
- English text analysis, stemming and accent folding
- Full-text search, field boosts and phrase ranking
- Quoted phrases, required/excluded terms, wildcard and fuzzy query syntax
- Completion-based autocomplete
- Genre and minimum-rating filters
- Genre and five-year histogram facets
- Highlighting, pagination and deterministic ordering
- Request parameter validation and normalized API errors
- Shared search-contract fixtures

## Architecture

The Nuxt frontend calls the Rails API over HTTP. The API translates request parameters into Elasticsearch Query DSL. The Rails TMDB sync service fetches movie metadata and indexes it into the `movies` index.

```text
                       ┌──────────────────┐
                       │     Nuxt 4       │
                       │    Frontend      │
                       └────────┬─────────┘
                                │ HTTP
                                ▼
                       ┌──────────────────┐
                       │   Rails 8 API    │
                       │ Search + Suggest │
                       └────────┬─────────┘
                                │ Elasticsearch Query DSL
                                ▼
                       ┌──────────────────┐
                       │ Elasticsearch    │
                       │   movies index   │
                       └────────▲─────────┘
                                │ document indexing
                       ┌────────┴─────────┐
                       │ Rails TMDB Sync  │
                       │ + genre mapping  │
                       └────────▲─────────┘
                                │ HTTP API
                                ▼
                       ┌──────────────────┐
                       │     TMDB API     │
                       └──────────────────┘
```

## Prerequisites

- Ruby version pinned in `backend/.ruby-version` (currently Ruby 3.4.5) and Bundler
- Node.js 22+ and pnpm 11.21.0 (the version used for validation)
- Docker and Docker Compose
- A TMDB v3 API key or v4 Read Access Token
- `curl`; `jq` is optional for formatted terminal output

If you use rbenv and the required Ruby version is missing, install it before setup:

```bash
rbenv install "$(cat backend/.ruby-version)"
```

The Rails Makefile includes `make ruby-check` and reports the required version when the active Ruby does not match. Installing Ruby does not install the application's gems; `make setup` or `make setup-backend` runs `bundle install` as well.

Elasticsearch is configured for a local single-node POC with security disabled. Do not expose this stack to a public network or use it as a production deployment.

## Quick start

Run all commands from the repository root.

The frontend uses pnpm 11. Its local `frontend/pnpm-workspace.yaml` explicitly allowlists the native dependency build scripts required by the current toolchain (`@parcel/watcher`, `esbuild`, `sharp`, and `vue-demi`). This keeps pnpm's build-script security checks enabled without requiring an interactive approval on every fresh install. Review this allowlist when direct frontend dependencies change. See the [pnpm 11 release notes](https://pnpm.io/blog/releases/11.0) and [workspace configuration documentation](https://pnpm.io/pnpm-workspace_yaml).

### 1. Configure environment variables

```bash
make setup-env
```

This creates `backend/.env` from `backend/.env.example` only when the local file does not exist. Add your TMDB v3 key or v4 Read Access Token to `backend/.env`. The Elasticsearch defaults are:

- `ELASTICSEARCH_URL=http://localhost:9200`
- `ELASTICSEARCH_INDEX=movies`
- `TMDB_SYNC_PAGES=25`

Do not commit local `.env` files or credentials.

### 2. Start services and install dependencies

```bash
make setup
```

This checks the Ruby version, creates any missing environment file, starts Elasticsearch and Kibana, waits for Elasticsearch, installs Ruby gems and Nuxt dependencies, and prepares the Rails database. It does not ingest movie data automatically.

| Service | URL |
| --- | --- |
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |
| Rails API | http://localhost:3000 |
| Nuxt frontend | http://localhost:3001 (override with `FRONTEND_PORT`) |

Check Elasticsearch:

```bash
make health
```

### 3. Ingest movie data

For a fresh index, recreate the index and ingest the configured number of TMDB popular-movie pages:

```bash
make ingest-reset CONFIRM_RESET=1
```

**Warning:** `ingest-reset` deletes and recreates the configured Elasticsearch index before ingestion. Use it only when replacing the existing index contents is acceptable.

To ingest or update without deleting the index:

```bash
make ingest
```

The Rails-native names are `make sync` and `make sync-reset`; `ingest` and `ingest-reset` are shared aliases to make the basic workflow consistent across both POCs. Override the page count for an individual run:

```bash
make ingest PAGES=25
make ingest-reset CONFIRM_RESET=1 PAGES=25
```

The sync service maps TMDB genre IDs to names, indexes each movie using the TMDB ID as Elasticsearch `_id`, refreshes the index, and reports successful indexing operations and the final unique document count. Repeated TMDB IDs update the same Elasticsearch document.

### 4. Prepare, test, and run the apps

Run just one part of setup when needed:

```bash
make setup-backend
make setup-frontend
```

TMDB ingestion uses the Rails backend, so `make setup-ingestion` is also available as an alias for installing the backend bundle.

Run tests and build the frontend:

```bash
make test
make build
# Or both:
make verify
```

Start the Rails API and Nuxt frontend in **separate terminals**:

```bash
make backend
```

```bash
make frontend
```

Open http://localhost:3001. Use `Ctrl+C` to stop each foreground process.

## Makefile commands

Run `make help` to list targets. The command names intentionally match the Node POC where their purposes overlap.

| Command | Description |
| --- | --- |
| `make setup` | Check Ruby, create env files, start infrastructure, install dependencies and prepare the database |
| `make setup-env` | Create the Rails environment file without overwriting an existing one |
| `make setup-backend` | Install Ruby gems and prepare the Rails database |
| `make setup-ingestion` | Compatibility alias; ingestion is implemented inside the Rails backend |
| `make setup-frontend` | Install Nuxt dependencies |
| `make up` / `make down` | Start/stop Elasticsearch and Kibana; data volume is preserved |
| `make wait-es` / `make health` | Wait for Elasticsearch / display cluster health |
| `make install` | Install backend and frontend dependencies |
| `make ingest PAGES=25` / `make sync PAGES=25` | Ingest/update TMDB movies without resetting the index |
| `make ingest-reset CONFIRM_RESET=1 PAGES=25` | Recreate the index and ingest data |
| `make test` | Run Rails/Minitest tests |
| `make build` / `make verify` | Build Nuxt / run tests and build |
| `make backend` / `make frontend` | Start Rails / Nuxt |
| `make index-info` | Inspect the configured Elasticsearch index |
| `make api-smoke` | Check health, browse search and suggestions |

`ES_PORT`, `KIBANA_PORT`, `ES_HEAP_SIZE`, `ES_MEM_LIMIT`, `API_PORT`, `FRONTEND_PORT`, `ES_URL`, `API_URL`, and `INDEX` can override defaults. The application uses `ELASTICSEARCH_URL` and `ELASTICSEARCH_INDEX` for its client and index name. The Nuxt frontend accepts `NUXT_PUBLIC_API_BASE` through its runtime configuration.

## Ingestion and index mapping

The model mapping is defined by `Movie` in `backend/app/models/movie.rb`. Indexed fields include `tmdb_id`, `title`, `original_title`, `short_description`, `overview`, `content`, `genres`, `year`, `release_date`, `original_language`, `popularity`, `vote_average`, `poster_url`, `poster_path`, and `backdrop_path`.

The Rails database stores genre names as JSON text in the existing `genres` column; `Movie#as_indexed_json` exposes genres to Elasticsearch as an array. Mapping changes require recreating and repopulating the index with the guarded `make ingest-reset CONFIRM_RESET=1` command.

## Search API contract

The Rails API listens on port 3000 by default and preserves the `items`, `facets`, and `took_ms` response fields consumed by the existing Nuxt frontend. The Node POC returns `hits`; cross-POC parity should be evaluated by matching document IDs, filters, query semantics, and expected ordering rather than forcing the same response envelope or equal Elasticsearch `_score` values.

### Health

`GET /api/health` returns HTTP 200 when Elasticsearch is reachable and HTTP 503 otherwise.

```bash
curl -i http://localhost:3000/api/health
```

### Search

`GET /api/search`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `q` | string | empty | Text query; empty query browses all indexed documents |
| `genres` | string | empty | Comma-separated exact genre filters, e.g. `Action,Drama` |
| `min_rating` / `minRating` | number | none | Minimum `vote_average`, from 0 to 10 |
| `from` | integer | `0` | Non-negative pagination offset |
| `size` | integer | `20` | Page size from 1 to 50 |

```bash
# Browse
curl -s "http://localhost:3000/api/search?size=5" | jq

# Search, phrase and exclusion
curl -sG --data-urlencode 'q="Spider-Man" -Homecoming' \
  "http://localhost:3000/api/search" | jq '{total, titles: [.items[].title]}'

# Search with facets and filters
curl -sG \
  --data-urlencode 'q=space adventure' \
  --data-urlencode 'genres=Science Fiction' \
  --data-urlencode 'min_rating=7' \
  "http://localhost:3000/api/search" | jq
```

### Query semantics

- Ordinary terms use `simple_query_string` with default operator `OR` for broad recall.
- A query containing an exclusion such as `"Spider-Man" -Homecoming` switches the default operator to `AND`, keeping the positive clause mandatory while excluding matches for the negative term.
- When Elasticsearch raises a `BadRequest` while executing a search query, the API returns HTTP 200 with an empty `items` payload to support incomplete queries while typing. Invalid HTTP parameters are still HTTP 400. An incomplete expression does not necessarily trigger an Elasticsearch error; live contract cases check the actual result.
- Supported syntax includes quoted phrases, AND composition with `+` (for example `space +adventure`), exclusions (`-`), wildcards, fuzzy terms and grouping supported by `simple_query_string`. In this engine, a leading unary `+space` is not treated as a required-term modifier.
- A separate phrase clause boosts ranking; it is not independently mandatory.
- Genre and rating filters do not directly contribute to relevance scoring.
- Text queries sort by score, then popularity and TMDB ID. Browse mode sorts by popularity and TMDB ID.
- Responses include genre facets, five-year histogram facets, and `<mark>` highlights.

### Suggestions

`GET /api/suggest?q=spi&size=5` uses the `title.suggest` completion field with fuzzy completion and duplicate skipping. The size must be between 1 and 10.

```bash
curl -s "http://localhost:3000/api/suggest?q=spi" | jq
```

### Movie lookup and validation

`GET /api/movies/:id` fetches a movie by TMDB ID (404 when it is not indexed). Invalid scalar parameters, pagination values, ratings or suggestion sizes return HTTP 400. Unexpected failures return a generic HTTP 500.

```bash
curl -i http://localhost:3000/api/movies/634649
curl -i "http://localhost:3000/api/search?from=-1"
curl -i "http://localhost:3000/api/search?size=51"
curl -i "http://localhost:3000/api/search?min_rating=11"
```

## Shared executable contract and parity checks

`contracts/search-cases.json` is consumed by `scripts/search-contract.mjs`. The runner can recreate a deterministic corpus in the isolated `movies-contract-test` index, call both live APIs, and compare ordered IDs, totals, genre/year facets, filter behavior, suggestions, browse ordering, and malformed-query handling. Exact Elasticsearch `_score` values are not compared.

Run the Node and Rails APIs against the same Elasticsearch instance and contract index, then run the contract script from either repository. The script will only recreate an index whose name ends with `-contract-test`; it refuses to seed the normal `movies` index.

```bash
# One Elasticsearch stack is enough; both APIs use the same index.
# Terminal 1 (from the Node POC):
make backend API_PORT=3000 ES_URL=http://localhost:9200 INDEX=movies-contract-test
# Terminal 2 (from this Rails repository):
make backend API_PORT=3100 ELASTICSEARCH_URL=http://localhost:9200 ELASTICSEARCH_INDEX=movies-contract-test
# Terminal 3:
make contract-smoke CONTRACT_SETUP_INDEX=1 \
  ES_URL=http://localhost:9200 CONTRACT_INDEX=movies-contract-test \
  NODE_API_URL=http://localhost:3000 RAILS_API_URL=http://localhost:3100
```

The same runner executes in CI using an isolated Elasticsearch service and fixture corpus. Run `make verify` for the fast Rails tests and Nuxt production build; `make api-smoke` checks only the Rails API.

## Troubleshooting

- **Ruby version missing:** run `make ruby-check` and install the version from `backend/.ruby-version` (with rbenv, use `rbenv install "$(cat backend/.ruby-version)"`).
- **Ruby version installed, gems missing:** run `make setup-backend` or rerun `make setup`; installation of Ruby and installation of Bundler gems are separate steps.
- **TMDB authentication fails:** check `TMDB_API_KEY` in `backend/.env`.
- **Frontend install reports `ERR_PNPM_IGNORED_BUILDS`:** confirm `frontend/pnpm-workspace.yaml` is present on your branch, then rerun `make setup-frontend`. The project explicitly allows only the listed dependency build scripts.
- **Elasticsearch health returns 503 with `ArgumentError` in JSON parsing:** run `make setup-backend` or `cd backend && bundle install`. The Rails Elasticsearch client requires `multi_json` 1.21.2 or later to work with JSON 3.x; this is constrained in the Gemfile and lockfile.
- **Elasticsearch unavailable:** run `make up`, inspect `make logs`, and verify `ELASTICSEARCH_URL`.
- **No search results:** confirm ingestion succeeded and the `movies` index exists with `make index-info`.
- **Mapping changed:** run the guarded reset and reingest data; this deletes the existing configured index.

## Frontend

The Nuxt 4 app uses the `frontend/app/` source directory. It includes debounced search, autocomplete suggestions, filters, highlighted results and pagination. Start it with `make frontend` and open http://localhost:3001.

## Running both POCs side by side

Each Docker Compose file now supports `ES_PORT`, `KIBANA_PORT`, `ES_HEAP_SIZE`, and `ES_MEM_LIMIT`. If you need both Elasticsearch stacks running concurrently, start one with non-default host ports, for example:

```bash
ES_PORT=9201 KIBANA_PORT=5602 ES_HEAP_SIZE=1g ES_MEM_LIMIT=2g make up
```

The API and frontend ports can be changed independently via `API_PORT` and `FRONTEND_PORT`. For cross-POC contract testing, using one Elasticsearch instance with a single shared contract index is more reproducible than keeping two independently ingested indexes.

## License

MIT
