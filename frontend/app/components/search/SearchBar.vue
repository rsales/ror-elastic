<script setup lang="ts">
import { useDebounceFn } from '@vueuse/core'

const modelValue = defineModel<string>({ default: '' })
const emit = defineEmits<{ submit: [q: string] }>()

const config = useRuntimeConfig()

const localQuery      = ref(modelValue.value)
const suggestions     = ref<any[]>([])
const showDropdown    = ref(false)
const highlightedIdx  = ref(-1)
const showHelp        = ref(false)

watch(modelValue, v => { localQuery.value = v })
watch(localQuery, v => { modelValue.value = v })

const fetchSuggestions = useDebounceFn(async (q: string) => {
  if (!q || q.length < 2) { suggestions.value = []; return }
  try {
    const r = await $fetch<{ suggestions: any[] }>(`${config.public.apiBase}/suggest`, { params: { q } })
    suggestions.value    = r.suggestions ?? []
    highlightedIdx.value = -1
  } catch {
    suggestions.value = []
  }
}, 250)

watch(localQuery, q => fetchSuggestions(q))

const onSubmit = () => {
  showDropdown.value = false
  emit('submit', localQuery.value)
}

const onBlur = () => {
  window.setTimeout(() => {
    showDropdown.value = false
  }, 150)
}

const onSelect = (s: any) => {
  localQuery.value   = s.title
  suggestions.value  = []
  showDropdown.value = false
}

const onKeydown = (e: KeyboardEvent) => {
  if (!suggestions.value.length) return
  if (e.key === 'ArrowDown') {
    e.preventDefault()
    highlightedIdx.value = Math.min(highlightedIdx.value + 1, suggestions.value.length - 1)
  } else if (e.key === 'ArrowUp') {
    e.preventDefault()
    highlightedIdx.value = Math.max(highlightedIdx.value - 1, -1)
  } else if (e.key === 'Enter' && highlightedIdx.value >= 0) {
    e.preventDefault()
    onSelect(suggestions.value[highlightedIdx.value])
  } else if (e.key === 'Escape') {
    showDropdown.value = false
  }
}

const posterUrl = (path: string | null) =>
  path ? `https://image.tmdb.org/t/p/w92${path}` : null
</script>

<template>
  <div class="search-bar">
    <div class="search-wrap">
      <input
        v-model="localQuery"
        type="text"
        placeholder='Buscar filmes… ("frase exata", +obrigatório, -excluir, termo*)'
        @keydown="onKeydown"
        @keydown.enter="onSubmit"
        @focus="showDropdown = true"
        @blur="onBlur"
      />
      <button class="btn-search" @click="onSubmit">Buscar</button>
    </div>

    <div class="search-actions">
      <button class="link-help" @click="showHelp = true">ℹ️ Dicas de busca</button>
    </div>

    <SearchHelpModal :visible="showHelp" @close="showHelp = false" />

    <ul v-if="showDropdown && suggestions.length" class="dropdown">
      <li
        v-for="(s, i) in suggestions"
        :key="s.id"
        :class="{ highlighted: i === highlightedIdx }"
        @mousedown.prevent="onSelect(s)"
      >
        <img v-if="posterUrl(s.poster_path)" :src="posterUrl(s.poster_path)!" alt="" class="thumb" />
        <div v-else class="thumb thumb-placeholder">🎬</div>
        <div class="info">
          <div class="s-title">{{ s.title }}</div>
          <div class="s-year">{{ s.release_date?.slice(0, 4) || '—' }}</div>
        </div>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.search-bar {
  position: relative;
}

.search-wrap {
  display: flex;
}

.search-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 6px;
}

.link-help {
  background: none;
  border: none;
  color: var(--muted);
  font-size: 12px;
  cursor: pointer;
  padding: 2px 4px;
  border-radius: 4px;
  transition: color 0.15s;
}

.link-help:hover { color: var(--accent); }

input[type="text"] {
  flex: 1;
  background: var(--bg);
  border: 1px solid var(--border);
  border-right: none;
  padding: 12px 16px;
  font-size: 15px;
  border-radius: 8px 0 0 8px;
  outline: none;
  transition: border-color 0.15s;
}

input[type="text"]:focus { border-color: var(--accent); }

.btn-search {
  background: var(--accent);
  color: white;
  border: 1px solid var(--accent);
  padding: 0 22px;
  font-size: 14px;
  font-weight: 500;
  border-radius: 0 8px 8px 0;
  cursor: pointer;
  transition: background 0.15s;
}

.btn-search:hover { background: var(--accent-2); }

.dropdown {
  position: absolute;
  top: calc(100% + 4px);
  left: 0;
  right: 0;
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 8px;
  box-shadow: 0 4px 16px rgba(0,0,0,0.4);
  list-style: none;
  margin: 0;
  padding: 4px 0;
  max-height: 360px;
  overflow-y: auto;
  z-index: 20;
}

.dropdown li {
  display: flex;
  gap: 12px;
  padding: 8px 12px;
  cursor: pointer;
  align-items: center;
}

.dropdown li.highlighted,
.dropdown li:hover { background: var(--bg); }

.thumb {
  width: 36px;
  height: 54px;
  object-fit: cover;
  border-radius: 3px;
  background: var(--bg);
  flex-shrink: 0;
}

.thumb-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 18px;
}

.s-title { font-weight: 500; font-size: 14px; }
.s-year  { font-size: 12px; color: var(--muted); }
</style>
