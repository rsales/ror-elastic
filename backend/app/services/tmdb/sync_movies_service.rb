module Tmdb
  class SyncMoviesService
    MAX_PAGES = 25

    def initialize
      @client = Tmdb::Client.new
    end

    def call
      (1..MAX_PAGES).each do |page|
        sync_page(page)
      end
    end

    private

    def sync_page(page)
      response = @client.popular_movies(page: page)

      movies = response['results']

      puts "Syncing page #{page}..."

      movies.each do |movie_data|
        upsert_movie(movie_data)
      end
    end

    def upsert_movie(movie_data)
      movie = Movie.find_or_initialize_by(
        tmdb_id: movie_data['id']
      )

      movie.update!(
        title: movie_data['title'],
        original_title: movie_data['original_title'],
        overview: movie_data['overview'],
        release_date: movie_data['release_date'],
        popularity: movie_data['popularity'],
        vote_average: movie_data['vote_average'],
        original_language: movie_data['original_language'],
        poster_path: movie_data['poster_path'],
        backdrop_path: movie_data['backdrop_path']
      )

      movie.__elasticsearch__.index_document
    end
  end
end