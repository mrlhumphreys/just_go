require 'forwardable'
require 'just_go/point'

module JustGo

  # = PointSet 
  #
  # A collection of Points with useful filtering functions
  class PointSet
    extend Forwardable

    def initialize(points: [])
      @points = case
        when !points.is_a?(Array)
          raise ArgumentError, 'points must be an array of Hash or Point'
        when points.all? { |p| p.is_a?(Hash) } 
          points.map { |p| JustGo::Point.new(p) }
        when points.all? { |p| p.is_a?(JustGo::Point) }
          points
        else
          raise ArgumentError, 'points must be an array of Hash or Point'
        end
    end

    attr_reader :points

    def_delegator :points, :find
    def_delegator :points, :map
    def_delegator :points, :size

    def as_json
      points.map(&:as_json)
    end

    def select(&block)
      _points = points.select(&block) 
      self.class.new(points: _points)
    end

    def find_by_id(point_id)
      find { |p| p.id == point_id }
    end

    def occupied
      select(&:occupied?)
    end

    def unoccupied
      select(&:unoccupied?)
    end

    def occupied_by(player_number)
      select { |p| p.occupied_by?(player_number) }
    end

    def occupied_by_opponent(player_number)
      select { |p| p.occupied_by_opponent?(player_number) }
    end

    def adjacent(point_or_chain)
      case point_or_chain
      when JustGo::Point
        select do |p| 
          vector = Vector.new(point_or_chain, p)
          vector.orthogonal? && vector.magnitude == 1
        end
      when JustGo::Chain
        _points = point_or_chain.points.map do |p|
          adjacent(p).points
        end.flatten.reject do |p| 
          point_or_chain.include?(p)
        end.uniq do |p|
          p.id
        end

        self.class.new(points: _points)
      else
        raise ArgumentError, 'Must be Point or Chain'
      end
    end

    def chains(chain_ids=nil)
      if chain_ids
        chain_ids.map do |c_id| 
          _points = select { |p| p.stone && p.stone.chain_id == c_id }.points
          JustGo::Chain.new(points: _points)
        end 
      else
        all_chain_ids = select { |p| p.stone }.map { |p| p.stone.chain_id }.uniq 
        chains(all_chain_ids)
      end
    end

    def liberties_for(point_or_chain)
      adjacent(point_or_chain).unoccupied.size
    end

    def deprives_liberties?(point, player_number)
      chain_ids = adjacent(point).occupied_by(player_number).map { |p| p.stone.chain_id }.uniq
      _chains = chains(chain_ids)
      _chains.all? { |c| liberties_for(c) == 1 }
    end

    def deprives_opponents_liberties?(point, player_number)
      chain_ids = adjacent(point).occupied_by_opponent(player_number).map { |p| p.stone.chain_id }.uniq
      _chains = chains(chain_ids)
      _chains.any? { |c| liberties_for(c) == 1 }
    end

    def update_joined_chains(point_id, player_number)
      point = find_by_id(point_id)
      existing_chain_ids = adjacent(point).occupied_by(player_number).map { |p| p.stone.chain_id }.uniq
      existing_chains = chains(existing_chain_ids)

      existing_chains.each do |c|
        c.points.each do |p|
          p.stone.join_chain(point.stone) 
        end
      end
    end

    def capture_stones(player_number)
      stone_count = 0

      chains.select do |c| 
        c.player_number != player_number && liberties_for(c) == 0 
      end.each do |c| 
        c.points.each do |p|
          p.capture_stone
          stone_count += 1
        end  
      end
      
      stone_count
    end

    def minify
      points.map do |p|
        player_number = p.stone && p.stone.player_number
        player_number ? player_number.to_s : '-'
      end.join
    end

    def place(point_id, stone)
      point = find_by_id(point_id)
      point.place(stone)
    end

    def next_stone_id
      (occupied.map { |p| p.stone.id }.max || 0) + 1
    end

    def adjacent_chain_id(point, player_number)
      adjacent(point).occupied_by(player_number).map { |p| p.stone.chain_id }.first
    end

    def next_chain_id
      (occupied.map { |p| p.stone.chain_id }.max || 0) + 1
    end

    def build_stone(point, player_number)
      JustGo::Stone.new(
        id: next_stone_id,
        player_number: player_number,
        chain_id: adjacent_chain_id(point, player_number) || next_chain_id
      )
    end

    def perform_move(point, player_number)
      stone = build_stone(point, player_number)
      place(point.id, stone)
      update_joined_chains(point.id, player_number)
      capture_stones(player_number)
    end

    def dup
      self.class.new(points: as_json)
    end
  end
end
