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
      must_clauses   = [simple_query_string]
      filter_clauses = build_filters

      if filter_clauses.any?
        { bool: { must: must_clauses, filter: filter_clauses } }
      else
        { bool: { must: must_clauses } }
      end
    end

    def simple_query_string
      {
        simple_query_string: {
          query:  query,
          fields: ['title^10', 'overview^2'],

          # OR: sem aspas, qualquer palavra basta (rankeado por relevância).
          # Isso torna os operadores significativos:
          #   "frase exata"  → só o que tem a frase na ordem
          #   +obrigatório   → termo deve estar presente
          #   -excluído      → termo não pode aparecer
          #   termo*         → wildcard/prefixo
          # Com 'and', o "+" vira redundante e "frase" vs sem-aspas fica igual.
          default_operator: 'or',

          # Força o analyzer padrão na busca (evita matches errados do edge_ngram)
          analyzer: 'standard'
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
