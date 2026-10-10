module Search
  class RequestParams
    class InvalidParameter < StandardError; end
    MAX_SAFE_INTEGER = 9_007_199_254_740_991

    def initialize(params)
      @params = params
    end

    def search
      {
        q: scalar(:q).to_s.strip,
        genres: parse_genres(scalar(:genres)),
        min_rating: parse_rating(first_value(:min_rating, :minRating)),
        from: parse_integer(:from, default: 0, min: 0),
        size: parse_integer(:size, default: 20, min: 1, max: 50)
      }
    end

    def suggestions
      {
        q: scalar(:q).to_s.strip,
        size: parse_integer(:size, default: 5, min: 1, max: 10)
      }
    end

    private

    def first_value(*keys)
      key = keys.find { |candidate| @params[candidate].present? }
      key ? scalar(key) : nil
    end

    def scalar(key)
      value = @params[key]
      return nil if value.nil?
      return value.to_s if value.is_a?(String) || value.is_a?(Numeric)

      raise InvalidParameter, %("#{key}" must be a single value)
    end

    def parse_integer(key, default:, min:, max: nil)
      value = scalar(key)
      return default if value.blank?
      unless value.match?(/\A-?\d+\z/)
        raise InvalidParameter, %("#{key}" must be an integer)
      end

      parsed = Integer(value, 10)
      upper = max || MAX_SAFE_INTEGER
      if parsed < min || parsed > upper
        raise InvalidParameter, %("#{key}" must be between #{min} and #{upper})
      end

      parsed
    end

    def parse_rating(value)
      return nil if value.blank?

      rating = Float(value)
      unless rating.finite? && rating >= 0 && rating <= 10
        raise InvalidParameter, '"min_rating" must be a number between 0 and 10'
      end

      rating
    rescue ArgumentError, TypeError
      raise InvalidParameter, '"min_rating" must be a number between 0 and 10'
    end

    def parse_genres(value)
      value.to_s.split(',').map(&:strip).reject(&:blank?)
    end
  end
end
