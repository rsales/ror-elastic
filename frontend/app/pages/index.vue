<script setup lang="ts">
const {
  query,
  loading,
  error,
  results,
  total,
  tookMs,
  facets,
  page,
  totalPages,
  selectedGenres,
  minRating,
  onFiltersChange,
  goToPage,
} = useSearch()
</script>

<template>
  <div class="app">
    <header class="header">
      <SearchHeader />
      <SearchBar v-model="query" />
    </header>

    <main class="main">
      <SearchFilters
        :facets="facets"
        :selected-genres="selectedGenres"
        :min-rating="minRating"
        @change="onFiltersChange"
      />

      <section class="results">
        <div class="results-meta">
          <span v-if="loading">Buscando…</span>
          <span v-else-if="error" class="error">Erro: {{ error }}</span>
          <span v-else>
            <strong>{{ total.toLocaleString() }}</strong> resultados
            <span class="took">({{ tookMs }}ms)</span>
            <span v-if="query" class="meta-q">para "<em>{{ query }}</em>"</span>
            <span v-else class="meta-q">— ordenado por popularidade</span>
          </span>
        </div>

        <MovieGrid :hits="results" />

        <SearchPagination
          v-if="totalPages > 1"
          :page="page"
          :total-pages="totalPages"
          @previous="goToPage(page - 1)"
          @next="goToPage(page + 1)"
        />
      </section>
    </main>
  </div>
</template>

<style scoped>
.app {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.header {
  padding: 24px 32px 20px;
  border-bottom: 1px solid var(--border);
  background: var(--panel);
  position: sticky;
  top: 0;
  z-index: 10;
}

.main {
  display: grid;
  grid-template-columns: 240px 1fr;
  gap: 24px;
  padding: 24px 32px;
  max-width: 1400px;
  width: 100%;
  margin: 0 auto;
  flex: 1;
}

.results-meta {
  margin-bottom: 16px;
  color: var(--muted);
  font-size: 13px;
}

.results-meta strong {
  color: var(--text);
}

.took {
  color: var(--muted);
  margin-left: 4px;
}

.meta-q {
  margin-left: 8px;
}

.error {
  color: #f87171;
}

@media (max-width: 800px) {
  .main {
    grid-template-columns: 1fr;
  }
}
</style>
