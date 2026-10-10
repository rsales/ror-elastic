# CLAUDE.md — ror-elastic

## What this is
Movie-search POC: **Rails 8.1 API** (Ruby 3.4.5) + **Elasticsearch 8.13** + **Nuxt 4 frontend** (TypeScript), data from TMDB.
It is the Rails half of a comparison with [`poc-elastic`](https://github.com/rsales/poc-elastic) (Express + Vue). Both must keep the same search behavior; each keeps the response envelope its own frontend expects.

Local POC only: ES runs single-node with security disabled. Never expose it publicly.

## Layout
```
backend/                      Rails API-only app (SQLite, Minitest, rubocop-rails-omakase)
  app/models/movie.rb         ES settings/mapping, as_indexed_json, index_document_by_tmdb_id!
  app/controllers/api/        health, search, suggest, movies (+ application_controller < ActionController::API)
  app/services/search/        request_params.rb (validation), movies_search_service.rb (Query DSL), movie_suggest_service.rb
  app/services/tmdb/          client.rb (HTTParty), sync_movies_service.rb (TMDB -> SQLite -> ES)
  app/jobs/sync_movies_job.rb Wraps the sync service (queue :default)
  config/routes.rb            Everything under /api
  config/initializers/        elasticsearch.rb (client from ELASTICSEARCH_URL), cors.rb (origins '*')
  test/services/search/       request_params_test.rb, movies_search_service_test.rb
frontend/app/                 Nuxt 4 srcDir
  pages/index.vue             Page; wires useSearch() to components
  composables/useSearch.ts    State, debounced search (300 ms), filters, pagination (PAGE_SIZE 20)
  components/{movie,search}/  MovieCard/Grid/Highlight; SearchBar/Filters/Header/HelpModal/Pagination/Results
contracts/search-cases.json   Shared behavior scenarios (prose expectations)
Makefile, docker-compose.yml
```
Template leftovers exist (Kamal, Solid Queue/Cache/Cable, Dockerfile, `.kamal/`); this POC is run locally only.

## Commands (from repo root)
| Task | Command |
|---|---|
| Setup (ruby check, env, ES, gems, DB, pnpm install) | `make setup` |
| Check Ruby vs `backend/.ruby-version` | `make ruby-check` |
| Start/stop ES + Kibana | `make up` / `make down` (volume preserved) |
| Sync TMDB, keep index | `make ingest PAGES=25` (= `make sync`) |
| Recreate index + sync | `make ingest-reset CONFIRM_RESET=1 PAGES=25` (= `make sync-reset`) |
| Backend tests / Nuxt build / both | `make test` / `make build` / `make verify` |
| Run API / UI (separate terminals) | `make backend` / `make frontend` |
| Health / index info / smoke | `make health` / `make index-info` / `make api-smoke` |

`PAGES` is passed to the sync as `TMDB_SYNC_PAGES`. Sync runs via `bin/rails runner 'Tmdb::SyncMoviesService.new.call'`.
Overrides: `ES_URL`, `API_URL`, `INDEX`. Quality tooling (not part of `make verify`): `bin/rubocop`, `bin/brakeman`, `bin/bundler-audit`, or `bin/ci`.

## Services
ES `:9200` · Kibana `:5601` · Rails `:3000` · Nuxt `:3001` (`pnpm dev --port 3001`).

## Environment
- `backend/.env` (from `.env.example`, gitignored): `TMDB_API_KEY` (v3 key, or v4 token starting with `eyJ`), `ELASTICSEARCH_URL`, `ELASTICSEARCH_INDEX=movies`, `TMDB_SYNC_PAGES=25`
- Frontend API base: `runtimeConfig.public.apiBase` in `nuxt.config.ts` = `http://localhost:3000/api` (override with `NUXT_PUBLIC_API_BASE`)
- Needs Ruby per `.ruby-version` + Bundler, Docker/Compose, Node 22+, pnpm. Never commit `.env` or credentials.

## API (Rails, `/api`)
- `GET /api/health` — 200 `{status:'ok', es}` or 503 `{status:'degraded'}`
- `GET /api/search` — `q`, `genres` (comma list), `min_rating` or `minRating` (0–10), `from` (>=0), `size` (1–50, default 20). Returns `{ total, took_ms, facets: { genres[], years[] }, items[] }`; hits are serialized explicitly in `SearchController#serialize_hit`
- `GET /api/suggest?q=&size=` — `{ suggestions: [...] }`, size 1–10 (default 5)
- `GET /api/movies/:id` — read straight from ES by TMDB ID; 404 `{error:'not found'}`
- `RequestParams::InvalidParameter` -> 400; ES `BadRequest` on search -> **200 with an empty result** (typing incomplete syntax); anything else -> 500 `{error:'internal server error'}`

## Search semantics (shared contract — keep in sync with poc-elastic)
- `bool.must` = `simple_query_string` over `title^3, short_description^2, overview^2, content^1`, `lenient: true`; empty `q` = `match_all`.
- Default operator `OR`; `AND` when the query matches `/(^|\s)-\S/`.
- `bool.should` = phrase `multi_match` (slop 1, boost 2) — ranking boost only.
- Filters (`terms` on `genres`, `range` on `vote_average`) are in `bool.filter`.
- Sort: text = `_score desc, popularity desc, tmdb_id asc`; browse = `popularity desc, tmdb_id asc`.
- Aggs: `genres` (terms, size 15), `years` (histogram, interval 5). Highlight uses `<mark>`.
- Suggest: completion on `title.suggest`, `skip_duplicates`, fuzziness `AUTO`.

## Index and ingestion
- `Movie` (`elasticsearch-model`) defines the mapping with `dynamic: false`; same `english_analyzer` and fields as poc-elastic. Index name from `ELASTICSEARCH_INDEX`.
- `as_indexed_json` builds the ES document. `genres` is stored in SQLite as JSON text and exposed as an array; legacy comma-separated values are tolerated.
- ES `_id` is the **TMDB ID**, never the ActiveRecord primary key: always index through `index_document_by_tmdb_id!`.
- `Tmdb::SyncMoviesService` (pages 1–500): maps genre IDs -> names, `find_or_initialize_by(tmdb_id)` + `update!`, indexes each movie, refreshes, counts. Per-movie failures are collected; the service raises `SyncFailed` at the end if any failed.
- Index is created only if missing. **Mapping changes need `make ingest-reset CONFIRM_RESET=1`.**

## Rules for working here
- `ingest-reset` deletes the ES index and needs `CONFIRM_RESET=1`. Never run it unprompted.
- Keep the `items` envelope and `min_rating`/`minRating` aliases; the Nuxt UI and shared contract depend on them. Parity with Node is judged on matching document IDs, filters, exclusions and relative ordering — not `_score`.
- Query-semantics changes go in `MoviesSearchService`, must be mirrored in `poc-elastic`, and reflected in `contracts/search-cases.json`.
- Add param validation in `Search::RequestParams` (raise `InvalidParameter`); keep controllers thin and logic in services.
- Style: rubocop-rails-omakase. Keep Makefile target names aligned with poc-elastic.
- Frontend: Composition API with `<script setup lang="ts">`; shared state lives in `useSearch.ts`.

## Gotchas
- Tests are unit-level (param parsing and the generated query/sort); nothing hits Elasticsearch, no controller/sync/frontend tests. `contracts/search-cases.json` is not executed. GitHub CI only runs brakeman, bundler-audit and rubocop — **not** `bin/rails test`.
- Sync is slower than the Node bulk path: one SQLite write and one ES index request per movie.
- Frontend: `@nuxt/ui` and Tailwind v4 are installed, but the components use scoped custom CSS and no `U*` components. The UI is in Portuguese; the Node UI is in English. `useSearch.ts` types and renders only the genre facet (`years` is returned but unused). Autocomplete in `SearchBar.vue` calls `/suggest` directly after 2+ characters.
- `frontend/pnpm-workspace.yaml` allowlists build scripts (`@parcel/watcher`, `esbuild`, `sharp`, `vue-demi`) via `allowBuilds` (pnpm 11 style). The README lists both "PNPM 10+" and "pnpm 11" — check which you have if you see `ERR_PNPM_IGNORED_BUILDS`.
- CORS is open (`origins '*'`) — fine locally, not for deployment.
- poc-elastic's compose uses the same host ports (9200, 5601) and its API also uses 3000, so both stacks cannot run at the same time.
- `frontend/README.md` and `backend/README.md` are template boilerplate (the former says dev port 3000; the real one is 3001).

## Differences vs poc-elastic
| | ror-elastic | poc-elastic |
|---|---|---|
| Backend | Rails 8.1 (API-only) | Express 4 |
| Frontend | Nuxt 4, TypeScript (:3001) | Vue 3 + Vite, JS (:5173) |
| Ingestion | Rails service, SQLite + per-record ES index | Node script, ES bulk |
| Routes | `/api/search`, `/api/suggest`, `/api/health`, `/api/movies/:id` | same without `/api` |
| Result key | `items` | `hits` |
| Min rating param | `min_rating` (also `minRating`) | `minRating` |
| Mapping defined in | `Movie` model | `mappings/movies.json` |
| Malformed query | ES 400 returns an empty 200 response | ES error likely surfaces as 500 (by code reading) |
| ES heap | 1 GB | 2 GB |