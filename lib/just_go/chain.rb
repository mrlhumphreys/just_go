require 'forwardable'

module JustGo

  # = Chain
  #
  # A collection of Points with stones of the same chain id
  class Chain
    extend Forwardable

    def initialize(points: [])
      @points = points
    end

    attr_reader :points

    def_delegator :points, :include?

    def player_number
      points.first.stone.player_number
    end
  end
end

