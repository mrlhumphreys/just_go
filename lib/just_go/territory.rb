require 'forwardable'

module JustGo

  # = Territory 
  #
  # A collection of Points with the same territory id
  class Territory 
    extend Forwardable

    def initialize(points: [])
      @points = points
    end

    attr_reader :points

    def_delegator :points, :include?
    def_delegator :points, :size

  end
end


