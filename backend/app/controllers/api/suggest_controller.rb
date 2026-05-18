class Api::SuggestController < ApplicationController
  SUGGEST_SIZE = 8

  def index
    q = params[:q].to_s.strip
    return render json: { suggestions: [] } if q.blank?

    results = Movie.search(build_query(q))
    render json: { suggestions: serialize(results) }

  rescue Elastic::Transport::Transport::Errors::BadRequest
    render json: { suggestions: [] }
  end

  private

  def build_query(q)
    {
      size:  SUGGEST_SIZE,
      query: {
        match: {
          title: {
            query:    q,
            operator: 'and'
          }
        }
      },
      _source: %w[title release_date poster_path vote_average]
    }
  end

  def serialize(results)
    hits = results.response.dig('hits', 'hits') || []
    hits.map do |hit|
      source = hit['_source']
      {
        id:           hit['_id'],
        title:        source['title'],
        release_date: source['release_date'],
        poster_path:  source['poster_path'],
        vote_average: source['vote_average']
      }
    end
  end
end
