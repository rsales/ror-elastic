# CLAUDE.md — ror-elastic

## What this is
Full-stack movie-search POC: **Ruby on Rails 8 API** + **Elasticsearch 8** + **Nuxt 4 frontend**. Movie data comes from TMDB.
This is the **Rails implementation** of a search experiment compared against the Node one in [`poc-elastic`](https://github.com/rsales/poc-elastic). Both share behavior scenarios in `contracts/search-cases.json`; each keeps the response envelope its own frontend expects.

Local POC only: Elasticsearch runs single-node with security disabled. Never expose it publicly.

## Layout
```
backend/      Rails 8 API (search + suggest + TMDB sync service), Minitest tests
              .ruby-version pins Ruby (currently 3.4.5)
              app/models/movie.rb defines ES mapping and Movie#as_indexed_json
frontend/     Nuxt 4 app (source in frontend/app/), pnpm
              pnpm-workspace.yaml allowlists native build scripts
contracts/    search-cases.json — behavior fixtures shared with poc-elastic
Makefile      Single entry point for all workflows
docker-compose.yml   Elasticsearch + Kibana
```
There is no separate ingestion project: TMDB sync lives inside the Rails backend.

## Commands (run from repo root)
| Task | Command |
|---|---|
| Full setup (ruby check, env, infra, gems, deps, DB) | `make setup` |
| Check active Ruby vs `.ruby-version` | `make ruby-check` |
| Start/stop ES + Kibana | `make up` / `make down` |
| Ingest/update (keeps index) | `make ingest PAGES=25` (alias `make sync`) |
| Recreate index + ingest | `make ingest-reset CONFIRM_RESET=1 PAGES=25` (alias `make sync-reset`) |
| Tests (Rails/Minitest) / Nuxt build / both | `make test` / `make build` / `make verify` |
| Run API / frontend (separate terminals) | `make backend` / `make frontend` |
| Health / index inspection / smoke | `make health` / `make index-info` / `make api-smoke` |

`make help` lists everything. `setup-ingestion` is just an alias for installing the backend bundle.
Helper overrides: `ES_URL`, `API_URL`, `INDEX`.

## Services
Elasticsearch `:9200` · Kibana `:5601` · Rails API `:3000` · Nuxt `:3001`

## Environment
- `backend/.env` (from `backend/.env.example`): `ELASTICSEARCH_URL` (http://localhost:9200), `ELASTICSEARCH_INDEX` (movies), `TMDB_SYNC_PAGES` (25), `TMDB_API_KEY` (v3 key or v4 Read Access Token)
- `make setup-env` creates it only if missing. **Never commit `.env` files or credentials.**
- Requires Ruby per `backend/.ruby-version` + Bundler, Node 22+, pnpm, Docker/Compose.
- Installing Ruby (e.g. `rbenv install "$(cat backend/.ruby-version)"`) does not install gems; `make setup-backend` runs `bundle install`.

## API (Rails, port 3000, under `/api`)
- `GET /api/health` — 200 if ES reachable, else 503
- `GET /api/search` — `q`, `genres` (comma-separated, exact), `min_rating` or `minRating` (0–10), `from` (>=0, default 0), `size` (1–50, default 20). Response: `items`, `facets`, `took_ms`
- `GET /api/suggest?q=&size=` — completion on `title.suggest`, fuzzy, skip duplicates; size 1–10
- `GET /api/movies/:id` — by TMDB ID; 404 if not indexed
- Invalid params -> 400; unexpected errors -> generic 500.

## Search semantics (keep stable; parity depends on them)
- `simple_query_string`, default operator `OR` (recall). A query with an exclusion (`"Spider-Man" -Homecoming`) switches to `AND`.
- Supports phrases, `+` required, `-` excluded, wildcards, fuzzy, grouping.
- A separate phrase clause **boosts** ranking; it is not mandatory.
- Genre/rating filters do not affect scoring.
- Sort: text query = score, popularity, TMDB ID; browse (empty `q`) = popularity, TMDB ID.
- Response includes genre facets, 5-year histogram facets, `<mark>` highlights.

## Index and ingestion
- Index `movies`; TMDB ID is the ES `_id` (re-syncing updates the same doc).
- Fields: `tmdb_id, title, original_title, short_description, overview, content, genres, year, release_date, original_language, popularity, vote_average, poster_url, poster_path, backdrop_path`.
- The Rails DB stores `genres` as JSON text; `Movie#as_indexed_json` exposes it to ES as an array.
- The sync service maps TMDB genre IDs to names, indexes, refreshes the index, and reports successful ops plus the final unique doc count.
- **Mapping changes require recreating the index** (`make ingest-reset CONFIRM_RESET=1`).

## Rules for working in this repo
- `ingest-reset` deletes the index — only run when explicitly intended; it needs `CONFIRM_RESET=1`.
- Don't change the response envelope (`items`) to match Node (`hits`) — the Nuxt frontend depends on it. Parity is checked by document IDs, filter correctness, exclusions and relative ordering, **not** exact `_score`.
- Behavior changes should update `contracts/search-cases.json` and stay compatible with `poc-elastic`.
- Keep Makefile target names aligned with `poc-elastic` where purposes overlap.
- Frontend uses pnpm with a build-script allowlist (`@parcel/watcher`, `esbuild`, `sharp`, `vue-demi`). Review `frontend/pnpm-workspace.yaml` when direct frontend dependencies change; don't bypass the check.
- Verify with `make verify`; `make api-smoke` needs the backend running and a populated index.

## Troubleshooting
- Ruby version missing -> `make ruby-check`, install per `.ruby-version`
- Gems missing -> `make setup-backend`
- TMDB auth error -> check `TMDB_API_KEY` in `backend/.env`
- `ERR_PNPM_IGNORED_BUILDS` -> confirm `frontend/pnpm-workspace.yaml` exists, rerun `make setup-frontend`
- ES unavailable -> `make up`, `make logs`, check `ELASTICSEARCH_URL`
- No results -> confirm ingestion ran, `make index-info`

## Differences vs poc-elastic
| | ror-elastic | poc-elastic |
|---|---|---|
| Backend | Rails 8 | Express |
| Frontend | Nuxt 4 (:3001) | Vue 3 + Vite (:5173) |
| Ingestion | Rails TMDB sync service | separate Node script |
| Routes | `/api/search`, `/api/suggest`, `/api/health` | `/search`, `/suggest`, `/health` |
| Result key | `items` | `hits` |
| Min rating param | `min_rating` (also `minRating`) | `minRating` |
| Mapping defined in | `Movie` model | `mappings/movies.json` |