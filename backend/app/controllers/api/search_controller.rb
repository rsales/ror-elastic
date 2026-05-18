class Api::SearchController < ApplicationController
  PAGE_SIZE = 20

  def index
    from = (params[:from] || 0).to_i
    size = (params[:size] || PAGE_SIZE).to_i

    results = search_movies(from: from, size: size)
    render json: serialize(results)

  rescue Elastic::Transport::Transport::Errors::BadRequest => e
    # query_string lança 400 quando a query tem sintaxe inválida
    # (ex: aspas não fechadas enquanto o usuário ainda está digitando)
    Rails.logger.warn("[SearchController] Malformed query '#{params[:q]}': #{e.message.truncate(120)}")
    render json: { total: 0, took_ms: 0, facets: { genres: [] }, items: [] }
  end

  private

  def search_movies(from:, size:)
    if params[:q].present?
      Search::MoviesSearchService.new(
        query:      params[:q],
        genres:     genres_param,
        min_rating: min_rating_param,
        from:       from,
        size:       size
      ).call
    else
      Movie.search(
        query: default_query,
        aggs:  facet_aggs,
        from:  from,
        size:  size
      )
    end
  end

  def default_query
    filters = build_filters
    return { match_all: {} } if filters.empty?
    { bool: { filter: filters } }
  end

  def serialize(results)
    response   = results.response
    hits       = response.dig('hits', 'hits') || []
    total_hits = response.dig('hits', 'total', 'value') || hits.count
    took_ms    = response['took'] || 0

    {
      total:   total_hits,
      took_ms: took_ms,
      facets:  serialize_facets(response['aggregations']),
      items:   hits.map { |hit| serialize_hit(hit) }
    }
  end

  def serialize_hit(hit)
    source = hit['_source']
    {
      id:                hit['_id'],
      score:             hit['_score'],
      title:             source['title'],
      overview:          source['overview'],
      genres:            source['genres'] || [],
      popularity:        source['popularity'],
      vote_average:      source['vote_average'],
      release_date:      source['release_date'],
      original_language: source['original_language'],
      poster_path:       source['poster_path'],
      backdrop_path:     source['backdrop_path'],
      highlight:         hit['highlight']
    }
  end

  def serialize_facets(aggs)
    return { genres: [] } if aggs.nil?

    {
      genres: (aggs.dig('genres', 'buckets') || []).map do |b|
        { value: b['key'], count: b['doc_count'] }
      end
    }
  end

  def genres_param
    params[:genres].present? ? params[:genres].split(',') : []
  end

  def min_rating_param
    params[:min_rating].present? ? params[:min_rating].to_f : nil
  end

  def build_filters
    filters = []
    genres  = genres_param
    rating  = min_rating_param

    filters << { terms: { genres: genres } }                    if genres.any?
    filters << { range: { vote_average: { gte: rating } } }     if rating
    filters
  end

  def facet_aggs
    {
      genres: {
        terms: { field: 'genres', size: 20 }
      }
    }
  end
end
