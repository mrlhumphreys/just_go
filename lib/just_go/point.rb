require 'just_go/stone'

module JustGo

  # = Point
  #
  # A Point on a go board
  class Point
    def initialize(id: , x: , y: , stone: , territory_id: nil)
      @id = id
      @x = x
      @y = y
      @stone = case stone
        when JustGo::Stone
          stone
        when Hash
          JustGo::Stone.new(**stone)
        when nil 
          stone
        else
          raise ArgumentError, "stone must be Stone, Hash or nil"
        end
      @territory_id = territory_id
    end

    attr_reader :id
    attr_reader :x
    attr_reader :y
    attr_reader :stone
    attr_reader :territory_id

    def as_json
      _stone = stone ? stone.as_json : nil
      {
        id: id,
        x: x,
        y: y,
        stone: _stone,
        territory_id: territory_id
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

    def unmarked?
      territory_id.nil?
    end

    def place(s)
      @stone = s
    end

    def capture_stone
      @stone = nil
    end

    def add_to_territory(t_id)
      @territory_id = t_id
    end

    def clear_territory
      @territory_id = nil
    end
  end
end
