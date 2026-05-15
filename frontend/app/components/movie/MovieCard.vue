<script setup lang="ts">
defineProps<{
  movie: any
}>()

const imageUrl = (path: string | null) => {
  if (!path) {
    return 'https://placehold.co/500x750?text=No+Image'
  }

  return `https://image.tmdb.org/t/p/w500${path}`
}
</script>

<template>
  <div
    class="
      bg-zinc-900
      rounded-2xl
      overflow-hidden
      transition
      hover:scale-[1.02]
      hover:bg-zinc-800
    "
  >
    <img
      :src="imageUrl(movie.poster_path)"
      :alt="movie.title"
      class="w-full h-[380px] object-cover"
    >

    <div class="p-4">
      <h2 class="font-bold line-clamp-1">
        {{ movie.title }}
      </h2>

      <div class="text-sm text-zinc-400 mt-2">
        ⭐ {{ movie.vote_average }}
      </div>

      <p class="text-sm text-zinc-300 mt-3 line-clamp-4">
        {{ movie.overview }}
      </p>
    </div>
  </div>
</template>