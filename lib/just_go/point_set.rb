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

    def update_joined_chains(point, player_number)
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
  end
end
