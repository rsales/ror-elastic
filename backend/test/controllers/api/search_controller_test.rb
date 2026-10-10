require 'test_helper'
require 'minitest/mock'

class Api::SearchControllerTest < ActionDispatch::IntegrationTest
  test 'normalizes Elasticsearch BadRequest to an empty successful search response' do
    error_class = Elastic::Transport::Transport::Errors::BadRequest
    error = error_class.new('invalid search query')
    search_service = Object.new
    search_service.define_singleton_method(:call) { raise error }

    service_factory = ->(*_args, **_kwargs) { search_service }

    Search::MoviesSearchService.stub(:new, service_factory) do
      get '/api/search', params: { q: '"Spider-Man' }
    end

    assert_response :success
    payload = response.parsed_body
    assert_equal 0, payload['total']
    assert_equal [], payload['items']
    assert_equal({ 'genres' => [], 'years' => [] }, payload['facets'])
  end

  test 'keeps invalid request parameters as HTTP 400' do
    get '/api/search', params: { from: '-1' }

    assert_response :bad_request
    assert response.parsed_body['error'].present?
  end
end
