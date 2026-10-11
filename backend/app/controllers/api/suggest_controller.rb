class Api::SuggestController < ApplicationController
  def index
    request = Search::RequestParams.new(params).suggestions
    render json: Search::MovieSuggestService.new(query: request[:q], size: request[:size]).call
  rescue Search::RequestParams::InvalidParameter => e
    render json: { error: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error("[SuggestController] Suggestions failed: #{e.class}: #{e.message}")
    render json: { error: "internal server error" }, status: :internal_server_error
  end
end
