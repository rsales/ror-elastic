<script setup lang="ts">
import type { SearchResult } from '~/composables/useSearch'

const props = defineProps<{ hit: SearchResult }>()

const TMDB_BASE = 'https://image.tmdb.org/t/p/w500'

const posterUrl = computed(() =>
  props.hit.poster_path ? `${TMDB_BASE}${props.hit.poster_path}` : null
)

const year = computed(() => props.hit.release_date?.slice(0, 4) ?? null)

const titleHtml = computed(() =>
  props.hit.highlight?.title?.[0] ?? escapeHtml(props.hit.title ?? '')
)

const descHtml = computed(() => {
  const fragments = props.hit.highlight?.overview
  if (fragments?.length) return fragments.join(' … ')
  const text = props.hit.overview ?? ''
  return escapeHtml(text).slice(0, 180) + (text.length > 180 ? '…' : '')
})

const ratingClass = computed(() => {
  const r = props.hit.vote_average
  if (r == null) return 'rating-na'
  if (r >= 7.5)  return 'rating-good'
  if (r >= 6)    return 'rating-mid'
  return 'rating-low'
})

const escapeHtml = (s: string) =>
  String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
</script>

<template>
  <article class="card">
    <div class="poster">
      <img v-if="posterUrl" :src="posterUrl" :alt="hit.title" loading="lazy" />
      <div v-else class="poster-placeholder">🎬</div>
      <span v-if="hit.vote_average != null" class="rating-badge" :class="ratingClass">
        {{ hit.vote_average.toFixed(1) }}
      </span>
    </div>

    <div class="meta">
      <h4 class="title" v-html="titleHtml" />

      <div class="year-score">
        <span>{{ year ?? '—' }}</span>
        <span v-if="hit.score" class="score" title="Elasticsearch _score">
          ⚡ {{ hit.score.toFixed(2) }}
        </span>
      </div>

      <p class="description" v-html="descHtml" />

      <div v-if="hit.genres?.length" class="genres">
        <span v-for="g in hit.genres.slice(0, 3)" :key="g" class="genre-tag">{{ g }}</span>
      </div>
    </div>
  </article>
</template>

<style scoped>
.card {
  background: var(--panel);
  border: 1px solid var(--border);
  border-radius: 8px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  transition: transform 0.15s, border-color 0.15s;
}

.card:hover {
  transform: translateY(-2px);
  border-color: var(--accent);
}

.poster {
  position: relative;
  aspect-ratio: 2 / 3;
  background: var(--bg);
}

.poster img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  display: block;
}

.poster-placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100%;
  font-size: 48px;
  color: var(--muted);
}

.rating-badge {
  position: absolute;
  top: 8px;
  right: 8px;
  padding: 2px 8px;
  border-radius: 12px;
  font-weight: 600;
  font-size: 12px;
  background: rgba(0,0,0,0.75);
  color: white;
  backdrop-filter: blur(4px);
}

.rating-good { color: #4ade80; }
.rating-mid  { color: #fbbf24; }
.rating-low  { color: #f87171; }

.meta {
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.title {
  margin: 0;
  font-size: 14px;
  font-weight: 600;
  line-height: 1.3;
}

.year-score {
  display: flex;
  justify-content: space-between;
  font-size: 11px;
  color: var(--muted);
}

.score { font-variant-numeric: tabular-nums; }

.description {
  margin: 4px 0 0 0;
  font-size: 12px;
  color: var(--muted);
  line-height: 1.4;
  display: -webkit-box;
  -webkit-line-clamp: 3;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.genres {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-top: auto;
  padding-top: 8px;
}

.genre-tag {
  font-size: 10px;
  background: var(--bg);
  color: var(--muted);
  padding: 2px 6px;
  border-radius: 8px;
  border: 1px solid var(--border);
}
</style>
