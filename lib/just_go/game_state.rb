require 'just_go/point_set'
require 'just_go/errors/not_players_turn_error'
require 'just_go/errors/point_not_empty_error'
require 'just_go/errors/point_not_found_error'
require 'just_go/errors/no_liberties_error'
require 'just_go/errors/ko_rule_violation_error'

module JustGo
  
  # = Game State
  # 
  # Represents a game of Go in progress.
  class GameState
    BOARD_SIZE = 19

    def initialize(current_player_number: , points: , prisoner_counts: , previous_state: nil)
      @current_player_number = current_player_number
      @points = JustGo::PointSet.new(points: points)
      @prisoner_counts = prisoner_counts
      @previous_state = previous_state
      @errors = []
      @last_change = {}
    end

    attr_reader :current_player_number 
    attr_reader :points
    attr_reader :prisoner_counts
    attr_reader :previous_state
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
        end.flatten,
        prisoner_counts: { 
          1 => 0,
          2 => 0,
        },
        previous_state: nil
      )
    end

    def as_json
      {
        current_player_number: current_player_number,
        points: points.as_json,
        prisoner_counts: prisoner_counts,
        previous_state: previous_state
      }
    end

    def move(player_number, point_id)
      @errors = []

      point = points.find_by_id(point_id)

      if current_player_number != player_number
        @errors.push JustGo::NotPlayersTurnError.new
      elsif point.nil?
        @errors.push JustGo::PointNotFoundError.new
      elsif point.occupied? 
        @errors.push JustGo::PointNotEmptyError.new
      elsif points.liberties_for(point).zero? && points.deprives_liberties?(point, player_number) && !points.deprives_opponents_liberties?(point, player_number)
        @errors.push JustGo::NoLibertiesError.new
      else
        dupped = points.dup
        dupped.perform_move(point, player_number)

        if dupped.minify == @previous_state
          @errors.push JustGo::KoRuleViolationError.new 
        else
          @previous_state = points.minify

          stone_count = points.perform_move(point, player_number)

          @prisoner_counts[player_number] += stone_count
        
          pass_turn
        end
      end
      
      errors.empty?
    end 

    private

    def pass_turn
      @current_player_number = next_player_number 
    end

    def next_player_number
      current_player_number == 1 ? 2 : 1
    end
  end
end
