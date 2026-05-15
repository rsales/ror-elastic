class Api::SearchController < ApplicationController
  def index
    results =
      if params[:q].present?
        Search::MoviesSearchService
          .new(query: params[:q])
          .call
      else
        Movie.search(
          sort: [
            {
              popularity: {
                order: 'desc'
              }
            }
          ],
          size: 20
        )
      end

    render json: serialize(results)
  end

  private

  def serialize(results)
    hits = results.response['hits']['hits']

    {
      total: hits.count,

      items: hits.map do |hit|
        source = hit['_source']

        {
          id: hit['_id'],
          score: hit['_score'],

          title: source['title'],
          overview: source['overview'],

          popularity: source['popularity'],
          vote_average: source['vote_average'],

          release_date: source['release_date'],

          original_language: source['original_language'],

          poster_path: source['poster_path'],
          backdrop_path: source['backdrop_path'],

          highlight: hit['highlight']
        }
      end
    }
  end
end