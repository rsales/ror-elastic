module Tmdb
  class Client
    include HTTParty

    base_uri "https://api.themoviedb.org/3"

    def initialize(api_key: ENV["TMDB_API_KEY"])
      @api_key = api_key.to_s.strip
      raise ArgumentError, "TMDB_API_KEY is required" if @api_key.blank?
    end

    def popular_movies(page: 1)
      get_json("/movie/popular", language: "en-US", page: page)
    end

    def movie_genres
      get_json("/genre/movie/list", language: "en-US").fetch("genres", [])
    end

    private

    def get_json(path, params = {})
      options = { headers: { "Accept" => "application/json" } }

      if @api_key.start_with?("eyJ")
        options[:headers]["Authorization"] = "Bearer #{@api_key}"
      else
        params = params.merge(api_key: @api_key)
      end

      response = self.class.get(path, options.merge(query: params))
      unless response.success?
        raise "TMDB request failed for #{path} (HTTP #{response.code})"
      end

      response.parsed_response
    end
  end
end
