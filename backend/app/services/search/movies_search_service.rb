module Search
  class MoviesSearchService
    def initialize(query:)
      @query = query
    end

    def call
      Movie.search(
        query: {
          simple_query_string: {
            query: query,
            fields: [
              'title^10',
              'overview^2'
            ],
            default_operator: 'and'
          }
        },

        highlight: {
          pre_tags: ['<mark>'],
          post_tags: ['</mark>'],
          fields: {
            overview: {}
          }
        }
      )
    end

    private

    attr_reader :query
  end
end