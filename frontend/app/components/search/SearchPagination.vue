<script setup lang="ts">
defineProps<{
  page: number
  totalPages: number
}>()

const emit = defineEmits<{
  previous: []
  next: []
}>()
</script>

<template>
  <div
    class="
      flex
      items-center
      justify-center
      gap-4
      mt-10
    "
  >
    <button
      class="
        px-4
        py-2
        rounded-xl
        bg-zinc-800
        hover:bg-zinc-700
        disabled:opacity-40
      "
      :disabled="page <= 1"
      @click="emit('previous')"
    >
      Previous
    </button>

    <div class="text-zinc-400">
      Page {{ page }} / {{ totalPages }}
    </div>

    <button
      class="
        px-4
        py-2
        rounded-xl
        bg-zinc-800
        hover:bg-zinc-700
        disabled:opacity-40
      "
      :disabled="page >= totalPages"
      @click="emit('next')"
    >
      Next
    </button>
  </div>
</template>