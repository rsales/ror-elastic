require "test_helper"

class Api::SearchControllerTest < ActionDispatch::IntegrationTest
  test "normalizes Elasticsearch BadRequest to an empty successful search response" do
    error_class = Elastic::Transport::Transport::Errors::BadRequest
    error = error_class.new("invalid search query")
    search_service = Object.new
    search_service.define_singleton_method(:call) { raise error }

    original_new = Search::MoviesSearchService.method(:new)
    Search::MoviesSearchService.singleton_class.define_method(:new) do |*args, **kwargs|
      search_service
    end

    get "/api/search", params: { q: "\"Spider-Man" }

    assert_response :success
    payload = response.parsed_body
    assert_equal 0, payload["total"]
    assert_equal [], payload["items"]
    assert_equal({ "genres" => [], "years" => [] }, payload["facets"])
  ensure
    Search::MoviesSearchService.singleton_class.define_method(:new, original_new) if original_new
  end

  test "keeps invalid request parameters as HTTP 400" do
    get "/api/search", params: { from: "-1" }

    assert_response :bad_request
    assert_not_nil response.parsed_body["error"]
  end
end
