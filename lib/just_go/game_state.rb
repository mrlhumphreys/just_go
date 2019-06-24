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
      # set not play turn error
      
      # check point is unoccupied
      # set point occupied error
      
      # check point for liberties
      # set point no liberties error
      
      # get next group id (adjacent or max)
      
      point = points.find_by_id(point_id)
      stone = build_stone(point_id, player_number) 
      point.place(stone)
      
      # check if captured stones
      # remove captured stones
      
      # check joined groups
      # update joined groups 
      
      pass_turn
      
      errors.empty?
    end 

    private

    def build_stone(point_id, player_number)
      JustGo::Stone.new(
        id: next_id,
        player_number: player_number,
        chain_id: adjacent_chain_id(point_id, player_number) || next_chain_id
      )
    end

    def next_id
      (points.occupied.map { |p| p.stone.id }.max || 0) + 1
    end

    def adjacent_chain_id(point_id, player_number)
      points.adjacent(point_id).occupied_by(player_number).map { |p| p.stone.chain_id }.first
    end

    def next_chain_id
      (points.occupied.map { |p| p.stone.chain_id }.max || 0) + 1
    end

    def pass_turn
      @current_player_number = next_player_number 
    end

    def next_player_number
      current_player_number == 1 ? 2 : 1
    end
  end
end
