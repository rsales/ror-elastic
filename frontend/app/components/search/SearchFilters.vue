<script setup lang="ts">
const genres = [
  'Action',
  'Comedy',
  'Drama',
  'Sci-Fi',
  'Horror',
  'Adventure'
]

const selectedGenre = defineModel<string | null>({
  default: null
})
</script>

<template>
  <div
    class="
      bg-zinc-900
      rounded-2xl
      p-6
      border
      border-zinc-800
    "
  >
    <h2 class="font-bold mb-4">
      Filters
    </h2>

    <div class="space-y-2">
      <button
        v-for="genre in genres"
        :key="genre"
        class="
          w-full
          text-left
          px-3
          py-2
          rounded-xl
          transition
        "
        :class="
          selectedGenre === genre
            ? 'bg-white text-black'
            : 'bg-zinc-800 hover:bg-zinc-700'
        "
        @click="selectedGenre = genre"
      >
        {{ genre }}
      </button>
    </div>
  </div>
</template>