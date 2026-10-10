require 'test_helper'

class Search::RequestParamsTest < ActiveSupport::TestCase
  test 'uses documented search defaults' do
    params = Search::RequestParams.new({}).search

    assert_equal '', params[:q]
    assert_equal [], params[:genres]
    assert_nil params[:min_rating]
    assert_equal 0, params[:from]
    assert_equal 20, params[:size]
  end

  test 'accepts both Rails and shared-contract rating parameter names' do
    assert_equal 7.5, Search::RequestParams.new(min_rating: '7.5').search[:min_rating]
    assert_equal 7.5, Search::RequestParams.new(minRating: '7.5').search[:min_rating]
  end

  test 'parses comma-separated genre filters' do
    params = Search::RequestParams.new(genres: 'Action, Drama ,,').search
    assert_equal %w[Action Drama], params[:genres]
  end

  test 'rejects invalid pagination values' do
    [
      { from: '-1' },
      { size: '51' },
      { size: '1.5' },
      { from: 'invalid' }
    ].each do |input|
      assert_raises(Search::RequestParams::InvalidParameter) do
        Search::RequestParams.new(input).search
      end
    end
  end

  test 'rejects ratings outside 0 to 10 and non-numeric values' do
    ['-1', '10.1', 'NaN', 'abc'].each do |value|
      assert_raises(Search::RequestParams::InvalidParameter) do
        Search::RequestParams.new(min_rating: value).search
      end
    end
  end

  test 'rejects arrays and objects for scalar parameters' do
    assert_raises(Search::RequestParams::InvalidParameter) do
      Search::RequestParams.new(q: ['spider', 'man']).search
    end
    assert_raises(Search::RequestParams::InvalidParameter) do
      Search::RequestParams.new(size: { nested: 'value' }).search
    end
  end

  test 'suggestions default to five and allow at most ten' do
    assert_equal 5, Search::RequestParams.new(q: 'spi').suggestions[:size]
    assert_equal 10, Search::RequestParams.new(q: 'spi', size: '10').suggestions[:size]

    assert_raises(Search::RequestParams::InvalidParameter) do
      Search::RequestParams.new(q: 'spi', size: '11').suggestions
    end
  end
end
