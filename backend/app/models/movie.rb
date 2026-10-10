class Movie < ApplicationRecord
  include Elasticsearch::Model

  index_name ENV.fetch('ELASTICSEARCH_INDEX', 'movies')

  TMDB_POSTER_BASE = 'https://image.tmdb.org/t/p/w342'.freeze

  settings index: {
    number_of_shards: 1,
    number_of_replicas: 0,
    analysis: {
      filter: {
        english_stop: {
          type: 'stop',
          stopwords: '_english_'
        },
        english_stemmer: {
          type: 'stemmer',
          language: 'english'
        },
        english_possessive_stemmer: {
          type: 'stemmer',
          language: 'possessive_english'
        }
      },
      analyzer: {
        english_analyzer: {
          type: 'custom',
          tokenizer: 'standard',
          filter: %w[
            english_possessive_stemmer
            lowercase
            asciifolding
            english_stop
            english_stemmer
          ]
        }
      }
    }
  } do
    mappings dynamic: false do
      indexes :tmdb_id, type: 'keyword'

      indexes :title,
        type: 'text',
        analyzer: 'english_analyzer',
        fields: {
          keyword: { type: 'keyword', ignore_above: 256 },
          suggest: { type: 'completion' }
        }

      indexes :original_title, type: 'text', analyzer: 'english_analyzer'
      indexes :short_description, type: 'text', analyzer: 'english_analyzer'
      indexes :overview, type: 'text', analyzer: 'english_analyzer'
      indexes :content, type: 'text', analyzer: 'english_analyzer'
      indexes :genres, type: 'keyword'
      indexes :year, type: 'integer'
      indexes :release_date, type: 'date'
      indexes :original_language, type: 'keyword'
      indexes :popularity, type: 'float'
      indexes :vote_average, type: 'float'
      indexes :poster_url, type: 'keyword', index: false
      indexes :poster_path, type: 'keyword', index: false
      indexes :backdrop_path, type: 'keyword', index: false
    end
  end

  # Persist genre names as JSON in the existing text column, but always expose
  # an array to Elasticsearch. This also tolerates legacy comma-separated values.
  def indexed_genres
    raw = self[:genres]
    return [] if raw.blank?
    return raw if raw.is_a?(Array)

    parsed = JSON.parse(raw)
    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError
    raw.split(',').map(&:strip).reject(&:blank?)
  end

  def as_indexed_json(_options = {})
    genre_names = indexed_genres
    content_parts = [
      genre_names.join(' '),
      original_title if original_title.present? && original_title != title,
      ("language #{original_language}" if original_language.present?)
    ].compact_blank

    {
      tmdb_id: tmdb_id.to_s,
      title: title,
      original_title: original_title,
      short_description: overview,
      overview: overview,
      content: content_parts.join(' | '),
      genres: genre_names,
      year: release_date&.year,
      release_date: release_date,
      original_language: original_language,
      popularity: popularity,
      vote_average: vote_average,
      poster_url: poster_path.present? ? "#{TMDB_POSTER_BASE}#{poster_path}" : nil,
      poster_path: poster_path,
      backdrop_path: backdrop_path
    }
  end

  # The cross-POC contract uses the TMDB ID as Elasticsearch's document ID.
  # Do not use the local ActiveRecord primary key for indexed document IDs.
  def index_document_by_tmdb_id!
    raise ArgumentError, 'tmdb_id is required before indexing a movie' if tmdb_id.blank?

    __elasticsearch__.index_document(id: tmdb_id.to_s)
  end
end
