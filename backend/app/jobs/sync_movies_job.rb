class SyncMoviesJob < ApplicationJob
  queue_as :default

  def perform(page = 1)
    response = Tmdb::Client.new.popular_movies(page: page)

    response['results'].each do |movie_data|
      movie = Movie.find_or_initialize_by(
        tmdb_id: movie_data['id']
      )

      movie.update!(
        title: movie_data['title'],
        original_title: movie_data['original_title'],
        overview: movie_data['overview'],
        popularity: movie_data['popularity'],
        vote_average: movie_data['vote_average'],
        original_language: movie_data['original_language'],
        poster_path: movie_data['poster_path'],
        backdrop_path: movie_data['backdrop_path'],
        release_date: movie_data['release_date']
      )

      movie.__elasticsearch__.index_document
    end
  end
end