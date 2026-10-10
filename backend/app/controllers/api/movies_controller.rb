class Api::MoviesController < ApplicationController
  def show
    document = Movie.__elasticsearch__.client.get(index: Movie.index_name, id: params[:id])
    render json: (document['_source'] || {}).merge('id' => document['_id'])
  rescue Elastic::Transport::Transport::Errors::NotFound
    render json: { error: 'not found' }, status: :not_found
  rescue StandardError => e
    Rails.logger.error("[MoviesController] Movie lookup failed: #{e.class}: #{e.message}")
    render json: { error: 'internal server error' }, status: :internal_server_error
  end
end
