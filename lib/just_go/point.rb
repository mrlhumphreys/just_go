require 'just_go/stone'

module JustGo

  # = Point
  #
  # A Point on a go board
  class Point
    def initialize(id: , x: , y: , stone: )
      @id = id
      @x = x
      @y = y
      @stone = case stone
        when JustGo::Stone
          stone
        when Hash
          JustGo::Stone.new(stone)
        when nil 
          stone
        else
          raise ArgumentError, "stone must be Stone, Hash or nil"
        end
    end

    attr_reader :id
    attr_reader :x
    attr_reader :y
    attr_reader :stone

    def as_json
      {
        id: id,
        x: x,
        y: y,
        stone: stone.as_json
      }
    end

    def ==(other)
      self.id == other.id
    end

    def occupied?
      !stone.nil?
    end

    def unoccupied?
      stone.nil?
    end

    def occupied_by?(player_number)
      !stone.nil? && stone.player_number == player_number
    end

    def occupied_by_opponent?(player_number)
      !stone.nil? && stone.player_number != player_number
    end

    def place(stone)
      @stone = stone
    end
  end
end
