require 'just_go/point'

module JustGo

  # = Just Go
  #
  # A collection of Points with useful filtering functions
  class PointSet
    def initialize(points: [])
      @points = case
        when !points.is_a?(Array)
          raise ArgumentError, 'points must be an array of Hash or Point'
        when points.all? { |p| p.is_a?(Hash) } 
          points.map { |p| JustGo::Point.new(p) }
        when points.all? { |p| p.is_a?(JustGo::Point) }
          points
        else
          raise ArgumentError, 'points must be an array of Hash or Point'
        end
    end

    attr_reader :points

    def as_json
      points.map(&:as_json)
    end
  end
end
