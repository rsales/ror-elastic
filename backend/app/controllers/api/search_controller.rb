class Api::SearchController < ApplicationController
  def index
    request = Search::RequestParams.new(params).search
    results = Search::MoviesSearchService.new(
      query: request[:q],
      genres: request[:genres],
      min_rating: request[:min_rating],
      from: request[:from],
      size: request[:size]
    ).call

    render json: serialize(results)
  rescue Search::RequestParams::InvalidParameter => e
    render json: { error: e.message }, status: :bad_request
  rescue Elastic::Transport::Transport::Errors::BadRequest => e
    # Incomplete query syntax can happen while someone is typing. Keep a stable,
    # empty response for this parser error instead of surfacing an Elasticsearch 400.
    Rails.logger.warn("[SearchController] Malformed query: #{e.message.truncate(120)}")
    render json: empty_response
  rescue StandardError => e
    Rails.logger.error("[SearchController] Search failed: #{e.class}: #{e.message}")
    render json: { error: 'internal server error' }, status: :internal_server_error
  end

  private

  def serialize(results)
    response = results.response
    hits = response.dig('hits', 'hits') || []
    total = response.dig('hits', 'total')
    total_hits = total.is_a?(Hash) ? total['value'] : total
    total_hits ||= hits.size

    {
      total: total_hits,
      took_ms: response['took'] || 0,
      facets: serialize_facets(response['aggregations']),
      items: hits.map { |hit| serialize_hit(hit) }
    }
  end

  def serialize_hit(hit)
    source = hit['_source'] || {}
    {
      id: hit['_id'],
      tmdb_id: source['tmdb_id'] || hit['_id'],
      score: hit['_score'],
      title: source['title'],
      original_title: source['original_title'],
      overview: source['overview'],
      short_description: source['short_description'],
      content: source['content'],
      genres: source['genres'] || [],
      year: source['year'],
      popularity: source['popularity'],
      vote_average: source['vote_average'],
      release_date: source['release_date'],
      original_language: source['original_language'],
      poster_url: source['poster_url'],
      poster_path: source['poster_path'],
      backdrop_path: source['backdrop_path'],
      highlight: hit['highlight'] || {}
    }
  end

  def serialize_facets(aggs)
    aggs ||= {}
    {
      genres: (aggs.dig('genres', 'buckets') || []).map do |bucket|
        { value: bucket['key'], count: bucket['doc_count'] }
      end,
      years: (aggs.dig('years', 'buckets') || []).map do |bucket|
        { value: bucket['key'].to_i, count: bucket['doc_count'] }
      end
    }
  end

  def empty_response
    { total: 0, took_ms: 0, facets: { genres: [], years: [] }, items: [] }
  end
end
