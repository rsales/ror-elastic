import { useDebounceFn } from '@vueuse/core'

export const useSearch = () => {
  const config = useRuntimeConfig()

  const query = ref('')

  const loading = ref(false)

  const results = ref<any[]>([])

  const fetchMovies = async () => {
    loading.value = true

    try {
      const response = await $fetch<{ items: any[] }>(
        `${config.public.apiBase}/search`,
        {
          params: {
            q: query.value
          }
        }
      )

      results.value = response.items
    } finally {
      loading.value = false
    }
  }

  const debouncedSearch = useDebounceFn(() => {
    fetchMovies()
  }, 300)

  watch(query, () => {
    debouncedSearch()
  })

  onMounted(() => {
    fetchMovies()
  })

  return {
    query,
    loading,
    results
  }
}