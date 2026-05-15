<script setup lang="ts">
defineProps<{
  movies: any[]
}>()
</script>

<template>
  <div
    class="
      grid
      grid-cols-2
      md:grid-cols-3
      lg:grid-cols-4
      xl:grid-cols-5
      gap-6
    "
  >
    <MovieCard
      v-for="movie in movies"
      :key="movie.id"
      :movie="movie"
    />
  </div>
</template>