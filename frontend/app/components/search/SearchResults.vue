<script setup lang="ts">
defineProps<{
  loading: boolean
  results: any[]
}>()
</script>

<template>
  <div>

    <div
      v-if="loading"
      class="text-zinc-400"
    >
      Loading...
    </div>

    <div
      v-else-if="results.length"
      class="
        grid
        grid-cols-2
        md:grid-cols-4
        lg:grid-cols-5
        gap-6
      "
    >
      <MovieCard
        v-for="movie in results"
        :key="movie.id"
        :movie="movie"
      />
    </div>

    <div
      v-else
      class="text-zinc-500 mt-10"
    >
      No results found
    </div>

  </div>
</template>