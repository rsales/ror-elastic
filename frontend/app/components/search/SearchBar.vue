<script setup lang="ts">
const modelValue = defineModel<string>({
  default: ''
})
</script>

<template>
  <div class="mb-10">
    <input
      v-model="modelValue"
      type="text"
      placeholder="Search movies..."
      class="
        w-full
        bg-zinc-900
        border
        border-zinc-800
        rounded-2xl
        px-5
        py-4
        text-white
        outline-none
        focus:border-zinc-600
      "
    >
  </div>
</template>