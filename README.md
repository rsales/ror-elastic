# ROR Elastic — Movie Search Engine POC

A modern search engine proof of concept using:

* Ruby on Rails API
* Nuxt 4
* ElasticSearch
* Kibana
* Docker Compose
* TMDB API

This project was inspired by:

* [https://github.com/rsalesSB/poc-elastic](https://github.com/rsalesSB/poc-elastic)

The goal is to build a search experience similar to:

* Google Search
* Netflix Search
* IMDb Search
* Algolia Instant Search

---

# Stack

## Backend

* Rails 8 API
* Solid Queue
* ElasticSearch Ruby
* HTTParty

## Frontend

* Nuxt 4
* TailwindCSS v4
* Nuxt UI
* VueUse
* PNPM

## Search Engine

* ElasticSearch 8
* Kibana

## Infrastructure

* Docker Compose
* Monorepo architecture

---

# Features

* Full-text search
* Google-style search
* Real-time search
* Debounced queries
* Highlight matches
* Search ranking
* Fuzzy search
* TMDB integration
* Movie cards
* Kibana inspection
* Elastic Query DSL
* Search API
* Responsive UI

---

# Project Structure

```text
ror-elastic/
├── backend/
│   ├── app/
│   ├── config/
│   ├── db/
│   └── ...
│
├── frontend/
│   ├── app/
│   │   ├── components/
│   │   ├── composables/
│   │   ├── pages/
│   │   └── assets/
│   │
│   └── ...
│
├── docker-compose.yml
├── Makefile
└── README.md
```

---

# Requirements

## Backend

* Ruby 3.4+
* Rails 8+

## Frontend

* Node.js 22+
* PNPM 10+

## Infrastructure

* Docker
* Docker Compose

---

# Getting Started

## Clone repository

```bash
git clone <repository-url>

cd ror-elastic
```

---

# ElasticSearch + Kibana

## Start services

```bash
make up
```

Or:

```bash
docker compose up -d
```

---

# Services

| Service       | URL                                            |
| ------------- | ---------------------------------------------- |
| ElasticSearch | [http://localhost:9200](http://localhost:9200) |
| Kibana        | [http://localhost:5601](http://localhost:5601) |
| Rails API     | [http://localhost:3000](http://localhost:3000) |
| Nuxt Frontend | [http://localhost:3001](http://localhost:3001) |

---

# Backend Setup

## Install dependencies

```bash
cd backend

bundle install
```

---

# Environment Variables

## backend/.env

```env
TMDB_API_KEY=YOUR_TMDB_API_KEY
ELASTICSEARCH_URL=http://localhost:9200
```

---

# Database

## Create database

```bash
rails db:create
rails db:migrate
```

---

# Start Rails API

```bash
make backend
```

Or:

```bash
cd backend

rails s
```

---

# Frontend Setup

## Install dependencies

```bash
cd frontend

pnpm install
```

---

# Start Nuxt

```bash
make frontend
```

Or:

```bash
cd frontend

pnpm dev --port 3001
```

---

# TMDB API

Create a TMDB account:

* [https://developer.themoviedb.org/docs/getting-started](https://developer.themoviedb.org/docs/getting-started)

Generate an API key and add it to:

```env
backend/.env
```

---

# Sync Movies

## Populate movies from TMDB

Open Rails console:

```bash
cd backend

rails c
```

Run:

```ruby
SyncMoviesJob.perform_now
```

---

# ElasticSearch Index

## Create index

```ruby
Movie.__elasticsearch__.create_index!(force: true)
```

---

# Reindex documents

```ruby
Movie.find_each do |movie|
  movie.__elasticsearch__.index_document
end
```

---

# Search API

## Endpoint

```text
GET /api/search?q=mario
```

---

# Example Response

```json
{
  "total": 5,
  "items": [
    {
      "title": "The Super Mario Galaxy Movie",
      "overview": "...",
      "score": 31.84
    }
  ]
}
```

---

# ElasticSearch Features

## Query DSL

Uses:

* multi_match
* simple_query_string
* fuzziness
* highlight
* ranking
* filters

---

# Search Operators

Supported operators:

| Operator     | Example         |
| ------------ | --------------- |
| Exact phrase | "super mario"   |
| Exclusion    | mario -kart     |
| AND          | mario AND luigi |
| OR           | mario OR zelda  |
| Fuzzy        | mraio           |

---

# Frontend Architecture

## Components

```text
frontend/app/components/
├── movie/
│   ├── MovieCard.vue
│   ├── MovieGrid.vue
│   └── MovieHighlight.vue
│
└── search/
    ├── SearchBar.vue
    ├── SearchFilters.vue
    ├── SearchHeader.vue
    ├── SearchPagination.vue
    └── SearchResults.vue
```

---

# Real-time Search

The frontend implements:

* watch(query)
* debounced search
* instant results
* loading states

Using:

```ts
useDebounceFn()
```

from VueUse.

---

# Docker Compose

## Current services

* ElasticSearch
* Kibana

---

# Makefile Commands

## Start ElasticSearch + Kibana

```bash
make up
```

---

## Stop containers

```bash
make down
```

---

## Start backend

```bash
make backend
```

---

## Start frontend

```bash
make frontend
```

---

## Open Kibana

```bash
make kibana
```

---

# Kibana

Access:

```text
http://localhost:5601
```

Useful for:

* inspecting indices
* testing queries
* analyzing mappings
* debugging scoring
* search tuning

---

# Future Improvements

## Search

* search_as_you_type
* autocomplete
* synonyms
* stemming
* semantic search
* vector search
* recommendations
* trending searches

## Frontend

* infinite scroll
* filters
* search history
* animations
* loading skeletons
* responsive improvements

## Backend

* pagination
* caching
* background sync
* API authentication
* rate limiting

---

# Development Notes

## Nuxt 4 Minimal

This project uses:

```text
app/
```

as the source directory.

Therefore:

* pages
* components
* assets
* composables

must be inside:

```text
frontend/app/
```

---

# CORS

Rails uses:

```ruby
rack-cors
```

configured in:

```text
backend/config/initializers/cors.rb
```

---

# License

MIT
