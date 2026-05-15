module Tmdb
  class Client
    include HTTParty

    base_uri 'https://api.themoviedb.org/3'

    def initialize
      @api_key = ENV['TMDB_API_KEY']
    end

    def popular_movies(page: 1)
      response = self.class.get(
        '/movie/popular',
        query: {
          api_key: @api_key,
          language: 'en-US',
          page: page
        }
      )

      response.parsed_response
    end
  end
end