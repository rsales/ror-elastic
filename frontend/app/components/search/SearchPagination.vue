<script setup lang="ts">
defineProps<{ page: number; totalPages: number }>()
const emit = defineEmits<{ previous: []; next: [] }>()
</script>

<template>
  <nav class="pager">
    <button :disabled="page <= 1" @click="emit('previous')">←</button>
    <span>Página {{ page }} de {{ totalPages }}</span>
    <button :disabled="page >= totalPages" @click="emit('next')">→</button>
  </nav>
</template>

<style scoped>
.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 16px;
  margin-top: 32px;
  color: var(--muted);
}

.pager button {
  background: var(--panel);
  color: var(--text);
  border: 1px solid var(--border);
  padding: 6px 14px;
  border-radius: 6px;
  cursor: pointer;
  font-size: 16px;
}

.pager button:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.pager button:not(:disabled):hover {
  border-color: var(--accent);
}
</style>
