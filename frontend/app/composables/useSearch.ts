import { useDebounceFn } from '@vueuse/core'

const PAGE_SIZE = 20

export interface Facet {
  value: string
  count: number
}

export interface SearchFacets {
  genres: Facet[]
}

export interface SearchResult {
  id: string
  score: number | null
  title: string
  overview: string | null
  vote_average: number | null
  release_date: string | null
  poster_path: string | null
  genres: string[]
  highlight: { title?: string[]; overview?: string[] } | null
}

export interface SearchResponse {
  total: number
  took_ms: number
  items: SearchResult[]
  facets: SearchFacets
}

export const useSearch = () => {
  const config = useRuntimeConfig()

  const query        = ref('')
  const loading      = ref(false)
  const error        = ref<string | null>(null)
  const results      = ref<SearchResult[]>([])
  const total        = ref(0)
  const tookMs       = ref(0)
  const facets       = ref<SearchFacets>({ genres: [] })
  const page         = ref(1)
  const selectedGenres = ref<string[]>([])
  const minRating    = ref<number | null>(null)

  const totalPages = computed(() => Math.ceil(total.value / PAGE_SIZE))

  const fetchMovies = async () => {
    loading.value = true
    error.value   = null

    try {
      const response = await $fetch<SearchResponse>(
        `${config.public.apiBase}/search`,
        {
          params: {
            q:          query.value || undefined,
            genres:     selectedGenres.value.length ? selectedGenres.value.join(',') : undefined,
            min_rating: minRating.value ?? undefined,
            from:       (page.value - 1) * PAGE_SIZE,
            size:       PAGE_SIZE,
          }
        }
      )

      results.value = response.items       ?? []
      total.value   = response.total       ?? 0
      tookMs.value  = response.took_ms     ?? 0
      facets.value  = response.facets      ?? { genres: [] }
    } catch (e: any) {
      error.value = e?.message ?? 'Erro ao buscar filmes'
    } finally {
      loading.value = false
    }
  }

  const debouncedSearch = useDebounceFn(fetchMovies, 300)

  // Ao digitar, volta para página 1 e busca com debounce
  watch(query, () => {
    page.value = 1
    debouncedSearch()
  })

  const onFiltersChange = ({ genres, minRating: rating }: { genres: string[]; minRating: number | null }) => {
    selectedGenres.value = genres
    minRating.value      = rating
    page.value           = 1
    fetchMovies()
  }

  const goToPage = (p: number) => {
    page.value = p
    fetchMovies()
    window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  onMounted(fetchMovies)

  return {
    query,
    loading,
    error,
    results,
    total,
    tookMs,
    facets,
    page,
    totalPages,
    selectedGenres,
    minRating,
    onFiltersChange,
    goToPage,
  }
}
