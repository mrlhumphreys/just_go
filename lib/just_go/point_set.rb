module JustGo

  # = Just Go
  #
  # A collection of Points with useful filtering functions
  class PointSet
    def initialize(points: [])
      @points = points
    end

    attr_reader :points
  end
end
