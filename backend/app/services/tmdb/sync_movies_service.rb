module Tmdb
  class SyncMoviesService
    DEFAULT_PAGES = 25
    MAX_PAGES = 500

    class SyncFailed < StandardError; end

    def initialize(pages: nil, reset_index: false, client: Tmdb::Client.new)
      @pages = parse_pages(pages || ENV.fetch('TMDB_SYNC_PAGES', DEFAULT_PAGES.to_s))
      @reset_index = reset_index
      @client = client
      @failures = []
      @indexed_operations = 0
    end

    def call
      prepare_index!
      genre_map = @client.movie_genres.index_by { |genre| genre['id'].to_i }
                      .transform_values { |genre| genre['name'] }

      (1..@pages).each { |page| sync_page(page, genre_map) }

      Movie.__elasticsearch__.client.indices.refresh(index: Movie.index_name)
      document_count = Movie.__elasticsearch__.client.count(index: Movie.index_name).fetch('count')

      Rails.logger.info(
        "[TMDB sync] pages=#{@pages} indexed_operations=#{@indexed_operations} " \
        "failed=#{@failures.size} elasticsearch_documents=#{document_count}"
      )

      if @failures.any?
        Rails.logger.error("[TMDB sync] Failed documents (first 20): #{@failures.first(20).to_json}")
        raise SyncFailed, "TMDB sync failed for #{@failures.size} document operation(s)"
      end

      {
        indexed_operations: @indexed_operations,
        failed_operations: @failures.size,
        elasticsearch_documents: document_count
      }
    end

    private

    def parse_pages(value)
      pages = Integer(value, 10)
      return pages if pages.between?(1, MAX_PAGES)

      raise ArgumentError, "pages must be between 1 and #{MAX_PAGES}"
    rescue ArgumentError, TypeError
      raise ArgumentError, "pages must be an integer between 1 and #{MAX_PAGES}"
    end

    def prepare_index!
      indices = Movie.__elasticsearch__.client.indices
      exists = indices.exists(index: Movie.index_name)

      if @reset_index && exists
        indices.delete(index: Movie.index_name)
        exists = false
      end

      Movie.__elasticsearch__.create_index! unless exists
    end

    def sync_page(page, genre_map)
      response = @client.popular_movies(page: page)
      movies = response.fetch('results', [])
      Rails.logger.info("[TMDB sync] page=#{page}/#{@pages} records=#{movies.size}")

      movies.each do |movie_data|
        index_movie(movie_data, genre_map)
      end
    end

    def index_movie(movie_data, genre_map)
      tmdb_id = movie_data['id']
      genre_names = Array(movie_data['genre_ids']).filter_map { |id| genre_map[id.to_i] }

      movie = Movie.find_or_initialize_by(tmdb_id: tmdb_id)
      movie.update!(
        title: movie_data['title'],
        original_title: movie_data['original_title'],
        overview: movie_data['overview'],
        release_date: movie_data['release_date'].presence,
        popularity: movie_data['popularity'],
        vote_average: movie_data['vote_average'],
        original_language: movie_data['original_language'],
        poster_path: movie_data['poster_path'],
        backdrop_path: movie_data['backdrop_path'],
        genres: genre_names.to_json
      )

      movie.index_document_by_tmdb_id!
      @indexed_operations += 1
    rescue StandardError => e
      @failures << { tmdb_id: tmdb_id, reason: "#{e.class}: #{e.message}" }
      Rails.logger.warn("[TMDB sync] Failed tmdb_id=#{tmdb_id}: #{e.class}: #{e.message}")
    end
  end
end
