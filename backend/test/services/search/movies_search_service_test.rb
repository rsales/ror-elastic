require "test_helper"

class Search::MoviesSearchServiceTest < ActiveSupport::TestCase
  test "uses OR for an ordinary query" do
    service = Search::MoviesSearchService.new(query: "Spider-Man")

    query = service.send(:full_text_query)
    assert_equal "OR", query.dig(:simple_query_string, :default_operator)
  end

  test "uses AND when an exclusion operator is present" do
    service = Search::MoviesSearchService.new(query: '"Spider-Man" -Homecoming')

    query = service.send(:full_text_query)
    assert_equal "AND", query.dig(:simple_query_string, :default_operator)
  end

  test "keeps phrase boosting separate from the required full-text clause" do
    service = Search::MoviesSearchService.new(query: '"Spider-Man" -Homecoming')

    bool_query = service.send(:build_query).dig(:query, :bool)
    assert_equal "simple_query_string", bool_query.dig(:must, 0).keys.first.to_s
    assert_equal "multi_match", bool_query.dig(:should, 0).keys.first.to_s
  end

  test "sorts text queries by score with deterministic tie-breakers" do
    service = Search::MoviesSearchService.new(query: "spider")
    assert_equal(
      [ { _score: "desc" }, { popularity: "desc" }, { tmdb_id: "asc" } ],
      service.send(:sort_config)
    )
  end

  test "sorts browse results by popularity and TMDB ID" do
    service = Search::MoviesSearchService.new(query: "")
    assert_equal(
      [ { popularity: "desc" }, { tmdb_id: "asc" } ],
      service.send(:sort_config)
    )
  end
end
