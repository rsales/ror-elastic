module Search
  class MoviesSearchService
    def initialize(query:, genres: [], min_rating: nil, from: 0, size: 20)
      @query      = query
      @genres     = genres
      @min_rating = min_rating
      @from       = from
      @size       = size
    end

    def call
      Movie.search(build_query)
    end

    private

    attr_reader :query, :genres, :min_rating, :from, :size

    def build_query
      {
        from:      from,
        size:      size,
        query:     build_bool_query,
        highlight: highlight_config,
        aggs:      facet_aggs
      }
    end

    def build_bool_query
      filter_clauses = build_filters

      if filter_clauses.any?
        { bool: { must: [full_text_query], filter: filter_clauses } }
      else
        full_text_query
      end
    end

    def full_text_query
      # query_string suporta todos os operadores de forma confiável:
      #   "frase exata"          → phrase query
      #   -excluído              → must_not (funciona mesmo com frases)
      #   +obrigatório           → must
      #   termo*                 → wildcard
      #   termo~2                → fuzzy
      #   (a OR b)               → agrupamento
      #
      # Diferente do simple_query_string, o query_string lida corretamente
      # com a combinação "phrase" -term sem explodir o minimum_should_match.
      # lenient: true garante que queries malformadas não retornem erro 400.
      # analyze_wildcard: true faz term* funcionar com o analyzer correto.
      {
        query_string: {
          query:             query,
          fields:            ['title^10', 'overview^2'],
          default_operator:  'OR',
          analyzer:          'standard',
          lenient:           true,
          analyze_wildcard:  true
        }
      }
    end

    def build_filters
      filters = []
      filters << { terms: { genres: genres } }                    if genres.any?
      filters << { range: { vote_average: { gte: min_rating } } } if min_rating
      filters
    end

    def highlight_config
      {
        pre_tags:  ['<mark>'],
        post_tags: ['</mark>'],
        fields: {
          title:    { number_of_fragments: 0 },
          overview: { number_of_fragments: 2, fragment_size: 200 }
        }
      }
    end

    def facet_aggs
      {
        genres: { terms: { field: 'genres', size: 20 } }
      }
    end
  end
end
