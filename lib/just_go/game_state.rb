require 'just_go/point_set'
require 'just_go/player_stat'
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

    def initialize(current_player_number: , points: , previous_state: nil, player_stats: [])
      @current_player_number = current_player_number
      @points = JustGo::PointSet.new(points: points)
      @previous_state = previous_state
      @player_stats = player_stats.map { |ps| JustGo::PlayerStat.new(ps) }
      @errors = []
      @last_change = {}
    end

    attr_reader :current_player_number 
    attr_reader :points
    attr_reader :previous_state
    attr_reader :player_stats
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
        previous_state: nil,
        player_stats: [
          { player_number: 1, prisoner_count: 0, passed: false },
          { player_number: 2, prisoner_count: 0, passed: false }
        ]
      )
    end

    def as_json
      {
        current_player_number: current_player_number,
        points: points.as_json,
        previous_state: previous_state,
        player_stats: player_stats.map(&:as_json)
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
          @player_stats.detect { |p| p.player_number == next_player_number }.mark_as_continuing 
          
          @previous_state = points.minify

          stone_count = points.perform_move(point, player_number)

          @player_stats.detect { |pc| pc.player_number == player_number }.add_to_prisoner_count(stone_count)

          pass_turn
        end
      end
      
      errors.empty?
    end 

    def pass(player_number)
      if current_player_number != player_number
        @errors.push JustGo::NotPlayersTurnError.new
      else
        @player_stats.detect { |ps| ps.player_number == player_number }.mark_as_passed 
        next_player_passed = @player_stats.detect { |ps| ps.player_number == next_player_number }.passed 
        if next_player_passed 
          points.mark_territories
        else
          pass_turn
        end
      end

      errors.empty?
    end

    def score
      [
        { player_number: 1, score: player_score(1) },
        { player_number: 2, score: player_score(2) }
      ]
    end

    def winner
      if @player_stats.map { |ps| ps.passed }.all?
        score.max_by { |line| line[:score] }[:player_number]
      else
        nil
      end
    end

    private

    def player_score(player_number)
      prisoner_count(player_number) + territory_count(player_number) 
    end

    def prisoner_count(player_number)
      player_stats.detect { |ps| ps.player_number == player_number }.prisoner_count
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
