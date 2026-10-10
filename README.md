# ROR Elastic — Movie Search POC

A full-stack movie-search proof of concept built with **Ruby on Rails 8**, **Elasticsearch 8**, **Nuxt 4**, and TMDB data. This POC is the Rails counterpart to [poc-elastic](https://github.com/rsales/poc-elastic) and is being aligned against a shared behavioral search contract as groundwork for Eloisesearch.

## Capabilities

- TMDB ingestion and bulk-search document modeling
- English analyzer with stemming and accent folding
- Full-text search with field boosts and phrase boosting
- Quoted phrases, required/excluded terms, wildcard and fuzzy syntax
- Completion-based autocomplete
- Genre and minimum-rating filters
- Genre and five-year histogram facets
- Highlighted matches
- Pagination and deterministic tie-breaking
- Request parameter validation and normalized API errors
- Shared behavior fixtures for comparison with the Node POC

## Architecture

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
                       │  Elasticsearch   │
                       │   movies index   │
                       └────────▲─────────┘
                                │ index documents
                       ┌────────┴─────────┐
                       │ Rails TMDB Sync  │
                       │  + genre mapping │
                       └────────▲─────────┘
                                │ HTTP API
                                ▼
                       ┌──────────────────┐
                       │     TMDB API     │
                       └──────────────────┘
```

## Prerequisites

- Ruby 3.4+ and Bundler
- Node.js 22+ and PNPM 10+
- Docker and Docker Compose
- A TMDB v3 API key or v4 Read Access Token
- `curl` (and optionally `jq`)

Elasticsearch is configured for a local single-node POC with security disabled. Do not expose this stack to a public network or use it as a production deployment.

## Quick start

Run commands from the repository root.

### 1. Configure Rails environment

```bash
cp backend/.env.example backend/.env
```

Set `TMDB_API_KEY` in `backend/.env`. The sync client supports the TMDB v3 API key and v4 Bearer token. The sample file also defines:

- `ELASTICSEARCH_URL=http://localhost:9200`
- `ELASTICSEARCH_INDEX=movies`
- `TMDB_SYNC_PAGES=25` (up to 20 movies per page)

Do not commit local `.env` files or API credentials.

### 2. Start services and install dependencies

```bash
make setup
```

This starts Elasticsearch/Kibana and installs the Rails and Nuxt dependencies.

| Service | URL |
| --- | --- |
| Elasticsearch | http://localhost:9200 |
| Kibana | http://localhost:5601 |
| Rails API | http://localhost:3000 |
| Nuxt frontend | http://localhost:3001 |

Check Elasticsearch:

```bash
make health
```

### 3. Prepare the database

```bash
cd backend
bin/rails db:create db:migrate
cd ..
```

### 4. Index movies from TMDB

For a fresh local index, re-create the Elasticsearch index and synchronize 25 pages (about 500 TMDB records):

```bash
make sync-reset CONFIRM_RESET=1 PAGES=25
```

**Warning:** `sync-reset` deletes and recreates the configured Elasticsearch index. Only use it when replacing that index's current contents is acceptable.

To ingest or update records without deleting the index:

```bash
make sync PAGES=25
```

The sync service maps TMDB genre IDs to genre names, writes the shared search fields, bulk-like indexes records one at a time, refreshes Elasticsearch, and reports both successful indexing operations and the final document count. It uses the TMDB ID as the Elasticsearch document ID, so duplicate IDs from different TMDB pages update the same indexed document.

The Rails database stores genre names as JSON text in the existing `genres` column; `Movie#as_indexed_json` exposes them to Elasticsearch as a JSON array. If mapping fields change, use `make sync-reset CONFIRM_RESET=1` to recreate the index and re-index documents.

### 5. Run tests and start both apps

Run the Rails contract tests:

```bash
make test
```

Start the API and frontend in separate terminals:

```bash
make backend
```

```bash
make frontend
```

Open http://localhost:3001.

## Makefile commands

Run `make help` for the list of targets.

| Command | Description |
| --- | --- |
| `make setup` | Start Elasticsearch/Kibana and install app dependencies |
| `make up` / `make down` | Start/stop containers; down preserves the data volume |
| `make logs` | Follow Docker Compose logs |
| `make health` | Check Elasticsearch health |
| `make elastic` / `make kibana` | Open local Elasticsearch/Kibana in a browser (macOS) |
| `make install` | Install Rails and Nuxt dependencies |
| `make sync PAGES=25` | Ingest/update TMDB movies without resetting the index |
| `make sync-reset CONFIRM_RESET=1 PAGES=25` | Recreate the index and ingest data |
| `make test` | Run Rails/Minitest tests |
| `make index-info` | Show the Elasticsearch index and document count |
| `make backend` / `make frontend` | Start Rails / Nuxt |
| `make api-smoke` | Check health, search and suggestions (API must be running) |

## Search API contract

The Rails API keeps the response envelope that the existing Nuxt frontend consumes (`items`, not the Node POC's `hits`). Parity is defined by query behavior, fields, filters, ordering expectations and error semantics; the two POCs need not use identical JSON envelopes or produce equal `_score` values.

### `GET /api/health`

Returns HTTP 200 when Elasticsearch is reachable, for example:

```json
{ "status": "ok", "es": "green" }
```

Returns HTTP 503 if Elasticsearch cannot be reached.

### `GET /api/search`

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `q` | string | empty | Text query; an empty query browses all indexed movies |
| `genres` | string | empty | Comma-separated exact genre filters, e.g. `Action,Drama` |
| `min_rating` / `minRating` | number | none | Minimum `vote_average`, from 0 to 10 |
| `from` | integer | `0` | Non-negative pagination offset |
| `size` | integer | `20` | Page size from 1 to 50 |

Examples:

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

The response shape is:

```json
{
  "total": 8,
  "took_ms": 14,
  "facets": {
    "genres": [{ "value": "Action", "count": 5 }],
    "years": [{ "value": 2020, "count": 3 }]
  },
  "items": [
    {
      "id": "Spider-Man TMDB ID",
      "tmdb_id": "Spider-Man TMDB ID",
      "score": 12.3,
      "title": "Spider-Man",
      "overview": "...",
      "genres": ["Action", "Adventure"],
      "highlight": { "title": ["<mark>Spider-Man</mark>"] }
    }
  ]
}
```

Values above are illustrative only. Actual results and relevance scores depend on the indexed dataset.

### Query semantics

- Ordinary terms use `simple_query_string` with the default operator `OR` for broad recall.
- Queries containing a negative term such as `-Homecoming` switch the default operator to `AND`, keeping the positive search clause mandatory. For example, `"Spider-Man" -Homecoming` should return Spider-Man results while excluding Homecoming matches, rather than broadening to unrelated documents.
- Explicit syntax includes phrases, required terms (`+`), excluded terms (`-`), wildcard prefixes, fuzzy terms and grouping supported by `simple_query_string`.
- Phrase matching adds a ranking boost; it is not a mandatory condition on its own.
- Genre and rating filters do not directly contribute to `_score`.
- Text search is sorted by `_score`, then popularity and TMDB ID. Browse mode uses popularity and TMDB ID for deterministic pagination.
- Facets contain genre counts and a five-year histogram.
- Highlights use `<mark>` tags on title and overview/description fields.

### `GET /api/suggest?q=spi&size=5`

Uses the `title.suggest` completion field and fuzzy completion. `size` must be from 1 to 10. A blank query returns `{ "suggestions": [] }`.

```bash
curl -s "http://localhost:3000/api/suggest?q=spi" | jq
```

Suggestion items include `id`, `title`, `year`, `release_date`, `poster_url`, `poster_path` and `vote_average`.

### `GET /api/movies/:id`

Fetches a movie by the TMDB ID used as the Elasticsearch document ID; returns HTTP 404 when it is not indexed.

```bash
curl -i http://localhost:3000/api/movies/634649
```

### Validation and errors

Invalid query parameters return HTTP 400. Try:

```bash
curl -i "http://localhost:3000/api/search?from=-1"
curl -i "http://localhost:3000/api/search?size=51"
curl -i "http://localhost:3000/api/search?min_rating=11"
curl -i "http://localhost:3000/api/suggest?q=spi&size=11"
```

Malformed Elasticsearch query syntax returns a stable empty search response; unexpected server failures return a generic HTTP 500 response.

## Shared fixtures and parity checks

The shared behavior scenarios live in `contracts/search-cases.json` and are intended for use by both `poc-elastic` and `ror-elastic`. Compare matching document IDs, filters, excluded terms and expected ordering—not exact Elasticsearch `_score` numbers.

Current Rails tests cover request validation, pagination bounds, rating limits, scalar parameters, OR/AND selection, phrase boosts, and deterministic sorting:

```bash
make test
```

## Troubleshooting

- **No results:** confirm `make sync` or `make sync-reset` completed and that the `movies` index exists.
- **TMDB authentication fails:** verify `TMDB_API_KEY` in `backend/.env`; both v3 keys and v4 Bearer tokens are supported.
- **Elasticsearch unavailable:** run `make up`, inspect `make logs`, and verify `ELASTICSEARCH_URL`.
- **Mapping changed:** recreate and repopulate the index with `make sync-reset CONFIRM_RESET=1`; this operation is destructive to the configured Elasticsearch index.

## Frontend structure

The Nuxt 4 app uses the `frontend/app/` source directory:

```text
frontend/app/
├── components/
│   ├── movie/
│   └── search/
├── composables/
├── pages/
└── assets/
```

## License

MIT
