class Movie < ApplicationRecord
  include Elasticsearch::Model
  include Elasticsearch::Model::Callbacks

  settings index: {
    number_of_shards: 1,

    analysis: {
      filter: {
        autocomplete_filter: {
          type: 'edge_ngram',
          min_gram: 1,
          max_gram: 20
        }
      },

      analyzer: {
        autocomplete: {
          tokenizer: 'standard',
          filter: %w[
            lowercase
            asciifolding
            autocomplete_filter
          ]
        }
      }
    }
  } do

    mappings dynamic: false do
      indexes :title,
        type: 'text',
        analyzer: 'autocomplete'

      indexes :overview,
        type: 'text'

      indexes :genres,
        type: 'keyword'

      indexes :original_language,
        type: 'keyword'

      indexes :popularity,
        type: 'float'

      indexes :vote_average,
        type: 'float'

      indexes :release_date,
        type: 'date'
    end
  end

  def as_indexed_json(_options = {})
    {
      title: title,
      overview: overview,
      genres: genres,
      popularity: popularity,
      vote_average: vote_average,
      release_date: release_date,
      original_language: original_language,
      poster_path: poster_path,
      backdrop_path: backdrop_path
    }
  end
end