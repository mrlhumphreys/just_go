require 'forwardable'
require 'just_go/vector'
require 'just_go/point'
require 'just_go/chain'
require 'just_go/territory'

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
    def_delegator :points, :each
    def_delegator :points, :size
    def_delegator :points, :all?

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

    def find_by_x_and_y(x, y)
      find { |p| p.x == x && p.y == y }
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

    def adjacent(point_or_group)
      case point_or_group
      when JustGo::Point
        select do |p| 
          vector = JustGo::Vector.new(point_or_group, p)
          vector.orthogonal? && vector.magnitude == 1
        end
      when JustGo::Chain
        _points = point_or_group.points.map do |p|
          adjacent(p).points
        end.flatten.reject do |p| 
          point_or_group.include?(p)
        end.uniq do |p|
          p.id
        end

        self.class.new(points: _points)
      when JustGo::Territory
        _points = point_or_group.points.map do |p|
          adjacent(p).points
        end.flatten.reject do |p| 
          point_or_group.include?(p)
        end.uniq do |p|
          p.id
        end

        self.class.new(points: _points)
      else
        raise ArgumentError, 'Must be Point or Chain or Territory'
      end
    end

    def where(args)
      scope = self
      args.each do |field, value|
        scope = scope.select do |p| 
          case value
          when Array
            value.include?(p.send(field))
          else
            p.send(field) == value 
          end
        end
      end
      scope
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

    def territories(territory_ids=nil)
      if territory_ids
        territory_ids.map do |t_id|
          _points = select { |p| p.territory_id == t_id }.points
          JustGo::Territory.new(points: _points)
        end
      else
        all_territory_ids = select(&:territory_id).map(&:territory_id).uniq
        territories(all_territory_ids)
      end
    end

    def territories_for(player_number)
      territories.select { |t| adjacent(t).all? { |p| p.occupied_by?(player_number) } }
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

    def mark_territories
      points.each(&:clear_territory)
      points.each do |point|
        if point.unoccupied? && point.unmarked?
          territory_ids = adjacent(point).unoccupied.map(&:territory_id).compact
          add_territory_id = case territory_ids.size
          when 0
            (points.map(&:territory_id).compact.max || 0) + 1 
          when 1
            territory_ids.first
          else
            min_id, *other_ids = territory_ids.sort
            where(territory_id: other_ids).each do |other_point|
              other_point.add_to_territory(min_id)
            end
            min_id 
          end

          point.add_to_territory(add_territory_id) 
        end
      end
    end
  end
end
