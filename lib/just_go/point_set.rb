require 'forwardable'
require 'just_go/point'

module JustGo

  # = Just Go
  #
  # A collection of Points with useful filtering functions
  class PointSet
    extend Forwardable

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

    def_delegator :points, :find
    def_delegator :points, :map

    def as_json
      points.map(&:as_json)
    end

    def select(&block)
      _points = points.select(&block) 
      self.class.new(points: _points)
    end

    def find_by_id(point_id)
      find { |p| p.id == point_id }
    end

    def occupied
      select(&:occupied?)
    end

    def occupied_by(player_number)
      select { |p| p.occupied_by?(player_number) }
    end

    def adjacent(point_id)
      point = find_by_id(point_id)
      select do |p| 
        vector = Vector.new(point, p)
        vector.orthogonal? && vector.magnitude == 1
      end
    end
  end
end
