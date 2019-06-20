module JustGo

  # = Point
  #
  # A Point on a go board
  class Point
    def initialize(id: , x: , y: , stone: )
      @id = id
      @x = x
      @y = y
      @stone = stone
    end

    attr_reader :id
    attr_reader :x
    attr_reader :y
    attr_reader :stone
  end
end
