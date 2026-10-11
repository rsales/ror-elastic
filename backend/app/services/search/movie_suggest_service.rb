module Search
  class MovieSuggestService
    def initialize(query:, size: 5)
      @query = query.to_s.strip
      @size = size
    end

    def call
      return { suggestions: [] } if @query.blank?

      response = Movie.search(
        size: 0,
        _source: %w[tmdb_id title year release_date poster_url poster_path vote_average],
        suggest: {
          title_suggest: {
            prefix: @query,
            completion: {
              field: "title.suggest",
              size: @size,
              skip_duplicates: true,
              fuzzy: { fuzziness: "AUTO" }
            }
          }
        }
      )

      options = response.response.dig("suggest", "title_suggest", 0, "options") || []
      { suggestions: options.map { |option| serialize_option(option) } }
    end

    private

    def serialize_option(option)
      source = option["_source"] || {}
      {
        text: option["text"],
        id: option["_id"] || source["tmdb_id"],
        title: source["title"] || option["text"],
        year: source["year"],
        release_date: source["release_date"],
        poster_url: source["poster_url"],
        poster_path: source["poster_path"],
        vote_average: source["vote_average"]
      }
    end
  end
end
