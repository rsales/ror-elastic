<script setup lang="ts">
defineProps<{
  highlight?: {
    overview?: string[]
  } | null
}>()
</script>

<template>
  <div
    v-if="highlight?.overview?.length"
    class="
      mt-3
      text-sm
      text-zinc-400
      italic
    "
  >
    <span
      v-html="highlight.overview[0]"
    />
  </div>
</template>