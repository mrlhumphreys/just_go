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

    def initialize(current_player_number: , points: , prisoner_counts: , previous_state: nil, passed: { 0 => false, 1 => false })
      @current_player_number = current_player_number
      @points = JustGo::PointSet.new(points: points)
      @prisoner_counts = prisoner_counts
      @previous_state = previous_state
      @passed = passed
      @errors = []
      @last_change = {}
    end

    attr_reader :current_player_number 
    attr_reader :points
    attr_reader :prisoner_counts
    attr_reader :previous_state
    attr_reader :passed
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
        prisoner_counts: [ 
          { player_number: 1, count: 0 },
          { player_number: 2, count: 0 },
        ],
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
          @passed[next_player_number] = false
          
          @previous_state = points.minify

          stone_count = points.perform_move(point, player_number)

          @prisoner_counts.detect { |pc| pc[:player_number] == player_number }[:count] += stone_count

          pass_turn
        end
      end
      
      errors.empty?
    end 

    def pass(player_number)
      if current_player_number != player_number
        @errors.push JustGo::NotPlayersTurnError.new
      else
        @passed[player_number] = true
        if @passed[next_player_number]
          points.mark_territories
        else
          pass_turn
        end
      end

      errors.empty?
    end

    def score
      {
        1 => player_score(1),
        2 => player_score(2) 
      }
    end

    def winner
      if @passed.values.all?
        score.max_by { |_player, score| score }.first
      else
        nil
      end
    end

    private

    def player_score(player_number)
      prisoner_count(player_number) + territory_count(player_number) 
    end

    def prisoner_count(player_number)
      prisoner_counts.detect { |pc| pc[:player_number] == player_number }[:count]
    end

    def territory_count(player_number)
      points.territories_for(player_number).sum(&:size)
    end

    def pass_turn
      @current_player_number = next_player_number 
    end

    def next_player_number
      current_player_number == 1 ? 2 : 1
    end
  end
end
