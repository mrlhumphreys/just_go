require 'just_go/point_set'

module JustGo
  
  # = Game State
  # 
  # Represents a game of Go in progress.
  class GameState
    BOARD_SIZE = 19

    def initialize(current_player_number: , points: )
      @current_player_number = current_player_number
      @points = JustGo::PointSet.new(points: points)
      @errors = []
      @last_change = {}
    end

    attr_reader :current_player_number 
    attr_reader :points
    attr_reader :errors 
    attr_reader :last_change 

    def self.default
      self.new(
        current_player_number: 1,
        points: BOARD_SIZE.times.map do |row|
          BOARD_SIZE.times.map do |col|
            { 
              id: row*BOARD_SIZE + col, 
              x: col, 
              y: row, 
              stone: nil 
            }
          end
        end.flatten
      )
    end

    def as_json
      {
        current_player_number: current_player_number,
        points: points.as_json
      }
    end

    def move(player_number, point_id)
      # check player
      # check point is unoccupied
      # place stone
    end 
  end
end
