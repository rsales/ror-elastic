module Search
  class MoviesSearchService
    def initialize(query:, genres: [], min_rating: nil, from: 0, size: 20)
      @query = query.to_s.strip
      @genres = genres
      @min_rating = min_rating
      @from = from
      @size = size
    end

    def call
      Movie.search(build_query)
    end

    private

    attr_reader :query, :genres, :min_rating, :from, :size

    def build_query
      {
        from: from,
        size: size,
        track_total_hits: true,
        query: query.present? ? build_search_query : build_browse_query,
        sort: sort_config,
        highlight: highlight_config,
        aggs: facet_aggs
      }
    end

    def build_search_query
      {
        bool: {
          must: [ full_text_query ],
          should: [ phrase_boost_query ],
          filter: build_filters
        }
      }
    end

    def build_browse_query
      clauses = { must: [ { match_all: {} } ] }
      filters = build_filters
      clauses[:filter] = filters if filters.any?
      { bool: clauses }
    end

    def full_text_query
      {
        simple_query_string: {
          query: query,
          fields: [ "title^3", "short_description^2", "overview^2", "content^1" ],
          default_operator: default_operator,
          lenient: true
        }
      }
    end

    def default_operator
      # Preserve broad OR recall for normal searches. If an exclusion is present,
      # AND keeps the positive expression mandatory, e.g. '"Spider-Man" -Homecoming'.
      query.match?(/(^|\s)-\S/) ? "AND" : "OR"
    end

    def phrase_boost_query
      {
        multi_match: {
          query: query,
          type: "phrase",
          fields: [ "title^3", "short_description^2", "overview^2" ],
          slop: 1,
          boost: 2
        }
      }
    end

    def build_filters
      filters = []
      filters << { terms: { genres: genres } } if genres.any?
      filters << { range: { vote_average: { gte: min_rating } } } unless min_rating.nil?
      filters
    end

    def sort_config
      if query.present?
        [ { _score: "desc" }, { popularity: "desc" }, { tmdb_id: "asc" } ]
      else
        [ { popularity: "desc" }, { tmdb_id: "asc" } ]
      end
    end

    def highlight_config
      {
        pre_tags: [ "<mark>" ],
        post_tags: [ "</mark>" ],
        fields: {
          title: { number_of_fragments: 0 },
          short_description: { fragment_size: 150, number_of_fragments: 2 },
          overview: { fragment_size: 150, number_of_fragments: 2 }
        }
      }
    end

    def facet_aggs
      {
        genres: { terms: { field: "genres", size: 15 } },
        years: { histogram: { field: "year", interval: 5, min_doc_count: 1 } }
      }
    end
  end
end
