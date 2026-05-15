<script setup lang="ts">
const {
  query,
  loading,
  results
} = useSearch()
</script>

<template>
  <div class="min-h-screen bg-zinc-950 text-white">
    <div class="max-w-7xl mx-auto px-6 py-10">

      <SearchHeader />

      <SearchBar
        v-model="query"
      />

      <div
        v-if="loading"
        class="text-zinc-400 mb-6"
      >
        Loading...
      </div>

      <MovieGrid
        :movies="results"
      />

    </div>
  </div>
</template>