require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/point_set'
require 'just_go/point'
require 'just_go/stone'
require 'just_go/chain'

describe JustGo::PointSet do
  describe 'initialize' do
    it 'must have attributes' do
      points = [{ id: 1, x: 2, y: 3, stone: nil}]
      point_set = JustGo::PointSet.new(points: points)
      assert point_set.points
    end

    it 'must handle empty array' do
      points = []
      point_set = JustGo::PointSet.new(points: points)
      assert_equal [], point_set.points
    end

    it 'must handle array of hashes' do
      points = [{ id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }]
      point_set = JustGo::PointSet.new(points: points)
      first_point = point_set.points.first

      assert_instance_of JustGo::Point, first_point
      assert_equal 1, first_point.id
      assert_equal 2, first_point.x
      assert_equal 3, first_point.y
      assert_instance_of JustGo::Stone, first_point.stone
      assert_equal 1, first_point.stone.id
      assert_equal 2, first_point.stone.player_number
    end

    it 'must handle array of points' do
      points = [JustGo::Point.new({ id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } })]
      point_set = JustGo::PointSet.new(points: points)
      first_point = point_set.points.first

      assert_instance_of JustGo::Point, first_point
      assert_equal 1, first_point.id
      assert_equal 2, first_point.x
      assert_equal 3, first_point.y
      assert_instance_of JustGo::Stone, first_point.stone
      assert_equal 1, first_point.stone.id
      assert_equal 2, first_point.stone.player_number
    end

    it 'must raise error for non array args' do
      assert_raises ArgumentError do
        JustGo::PointSet.new(points: 42)
      end
    end

    it 'must raise error for array of invalid elements' do
      assert_raises ArgumentError do
        JustGo::PointSet.new(points: [1,1,2,3,5])
      end
    end

    it 'must raise error for array of mixed valid elements' do
      assert_raises ArgumentError do
        points = [JustGo::Point.new({ id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }), { id: 4, x: 5, y: 7, stone: nil}]
        point_set = JustGo::PointSet.new(points: points)
      end

    end
  end

  describe '#as_json' do
    it 'must return a array of hashes with attributes' do
      points = [{ id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }]
      point_set = JustGo::PointSet.new(points: points)
      result = point_set.as_json
      expected = [
        { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: nil } }
      ]

      assert_equal expected, result
    end
  end

  describe '#find_by_id' do
    it 'returns a point matching the id' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: nil },
        { id: 1, x: 1, y: 0, stone: nil },
        { id: 2, x: 2, y: 0, stone: nil }
      ])
      point_id = 1

      point = point_set.find_by_id(point_id)

      assert_instance_of JustGo::Point, point
      assert_equal point_id, point.id 
    end
  end

  describe '#occupied' do
    it 'must return points where stone is not nil' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: nil },
        { id: 2, x: 2, y: 0, stone: nil }
      ])

      result = point_set.occupied

      assert result.points.all? { |p| !p.stone.nil? }
    end
  end

  describe '#unoccupied' do
    it 'must return all points where stone is nil' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: nil },
        { id: 2, x: 2, y: 0, stone: nil }
      ])

      result = point_set.unoccupied  
      
      assert result.points.all? { |p| p.stone.nil? }
    end
  end

  describe '#adjacent' do
    describe 'with a point' do
      it 'must return the points next to and orthogonal to the point' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: nil },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: nil },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: nil },
        ])

        point_id = 4
        point = point_set.points.find { |p| p.id == point_id }

        result = point_set.adjacent(point)

        assert_equal [1, 3, 5, 7], result.points.map(&:id)
      end
    end

    describe 'with a chain' do
      it 'must return the points next to and orthogonal to the chain' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: nil },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 5, x: 2, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: nil },
        ])

        chain = JustGo::Chain.new(points: [
          point_set.points.find { |p| p.id == 4 },  
          point_set.points.find { |p| p.id == 5 }  
        ])

        result = point_set.adjacent(chain)

        assert_equal [1, 2, 3, 7, 8], result.points.map(&:id).sort
      end

      it 'must return unique points' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 2, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 8, x: 2, y: 2, stone: { id: 1, player_number: 1, chain_id: 1 } },
        ])

        chain = JustGo::Chain.new(points: [
          point_set.points.find { |p| p.id == 1 },  
          point_set.points.find { |p| p.id == 2 },  
          point_set.points.find { |p| p.id == 5 },  
          point_set.points.find { |p| p.id == 7 },  
          point_set.points.find { |p| p.id == 8 }  
        ])

        result = point_set.adjacent(chain)

        assert_equal [0, 4, 6], result.points.map(&:id).sort
      end
    end
  end

  describe '#occupied_by' do
    it 'must return all points occupied by player' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: nil },
        { id: 2, x: 2, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } }
      ])
      player_number = 1
      
      result = point_set.occupied_by(player_number)

      assert result.points.all? { |p| p.stone.player_number == player_number }
    end
  end

  describe '#occupied_by_opponent' do
    it 'must return all points occupied by player' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: nil },
        { id: 2, x: 2, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } }
      ])
      player_number = 1
      opponent_number = 2
      
      result = point_set.occupied_by_opponent(player_number)

      assert result.points.all? { |p| p.stone.player_number == opponent_number }
    end
  end

  describe '#chains' do
    describe 'specifying chain_ids' do
      it 'must return an array of chains' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 2, chain_id: 2 } },
          { id: 3, x: 0, y: 1, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 2, chain_id: 2 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 2, chain_id: 2 } }
        ])

        chain_id = 1
        result = point_set.chains([chain_id])

        assert result.all? { |c| c.is_a?(JustGo::Chain) }
        assert result.all? { |c| c.points.first.stone.chain_id == chain_id }
      end
    end

    describe 'with no chain_ids passed in' do
      it 'must return all chains' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 2, chain_id: 2 } },
          { id: 3, x: 0, y: 1, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 2, chain_id: 2 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 2, chain_id: 2 } }
        ])

        chain_id = 1
        result = point_set.chains

        assert_equal 2, result.size
        assert result.all? { |c| c.is_a?(JustGo::Chain) }
      end
    end
  end

  describe '#liberties_for' do
    describe 'with empty points adjacent' do
      it 'must return the number of empty points adjacent' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: { id: 7, player_number: 1, chain_id: 1 } },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 1 } }
        ])
        point = point_set.points.find { |p| p.id == 4 } 
        player_number = 2

        result = point_set.liberties_for(point)

        assert_equal 2, result
      end
    end

    describe 'with no empty points adjacent' do
      it 'must return 0' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 1, chain_id: 1 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: { id: 7, player_number: 1, chain_id: 1 } },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 1 } }
        ])
        point = point_set.points.find { |p| p.id == 4 } 
        player_number = 2

        result = point_set.liberties_for(point)

        assert_equal 0, result
      end
    end
  end

  describe '#deprives_liberties?' do
    describe 'when the adjacent friendly chain has 1 liberty' do
      it 'must return true' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: { id: 7, player_number: 1, chain_id: 1 } },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 1 } }
        ])
        point = point_set.points.find { |p| p.id == 4 } 
        player_number = 2

        result = point_set.deprives_liberties?(point, player_number)
        assert result
      end 
    end

    describe 'when the adjacent friendly chain has more than 1 liberty' do
      it 'must return false' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 7, x: 1, y: 2, stone: { id: 7, player_number: 1, chain_id: 1 } },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 1 } }
        ])
        point = point_set.points.find { |p| p.id == 4 } 
        player_number = 2

        result = point_set.deprives_liberties?(point, player_number)
        refute result
      end
    end
  end

  describe '#deprives_opponents_liberties?' do
    describe 'when move deprives adjacent opponents chains liberties' do
      it 'must return true' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 1, chain_id: 1 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 3, y: 0, stone: { id: 4, player_number: 1, chain_id: 1 } },
          { id: 4, x: 4, y: 0, stone: { id: 5, player_number: 1, chain_id: 1 } },

          { id: 5, x: 0, y: 1, stone: { id: 6, player_number: 1, chain_id: 1 } },
          { id: 6, x: 1, y: 1, stone: { id: 7, player_number: 2, chain_id: 2 } },
          { id: 7, x: 2, y: 1, stone: { id: 8, player_number: 2, chain_id: 2 } },
          { id: 8, x: 3, y: 1, stone: { id: 9, player_number: 2, chain_id: 2 } },
          { id: 9, x: 4, y: 1, stone: { id: 10, player_number: 1, chain_id: 1 } },

          { id: 10, x: 0, y: 2, stone: { id: 11, player_number: 1, chain_id: 1 } },
          { id: 11, x: 1, y: 2, stone: { id: 12, player_number: 2, chain_id: 2 } },
          { id: 12, x: 2, y: 2, stone: nil },
          { id: 13, x: 3, y: 2, stone: { id: 13, player_number: 2, chain_id: 2 } },
          { id: 14, x: 4, y: 2, stone: { id: 14, player_number: 1, chain_id: 1 } },

          { id: 15, x: 0, y: 3, stone: { id: 15, player_number: 1, chain_id: 1 } },
          { id: 16, x: 1, y: 3, stone: { id: 16, player_number: 2, chain_id: 2 } },
          { id: 17, x: 2, y: 3, stone: { id: 17, player_number: 2, chain_id: 2 } },
          { id: 18, x: 3, y: 3, stone: { id: 18, player_number: 2, chain_id: 2 } },
          { id: 19, x: 4, y: 3, stone: { id: 19, player_number: 1, chain_id: 1 } },

          { id: 20, x: 0, y: 4, stone: { id: 20, player_number: 1, chain_id: 1 } },
          { id: 21, x: 1, y: 4, stone: { id: 21, player_number: 1, chain_id: 1 } },
          { id: 22, x: 2, y: 4, stone: { id: 22, player_number: 1, chain_id: 1 } },
          { id: 23, x: 3, y: 4, stone: { id: 23, player_number: 1, chain_id: 1 } },
          { id: 24, x: 4, y: 4, stone: { id: 24, player_number: 1, chain_id: 1 } }
        ])

        point = point_set.points.find { |p| p.id == 12 } 
        player_number = 1 

        result = point_set.deprives_opponents_liberties?(point, player_number)
        assert result
      end
    end
  end

  describe '#update_joined_chains' do
    describe 'with point adjacent to some chains' do
      it 'must update the chains that are adjacent' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 1, chain_id: 1 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 5, x: 2, y: 1, stone: nil },
          { id: 6, x: 0, y: 2, stone: { id: 6, player_number: 1, chain_id: 2 } },
          { id: 7, x: 1, y: 2, stone: { id: 7, player_number: 1, chain_id: 2 } },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 2 } }
        ])

        point_id = 4
        player_number = 1

        point_set.update_joined_chains(point_id, player_number)
        
        assert_equal 1, point_set.points.select { |p| [0, 1, 2, 4, 6, 7, 8].include?(p.id) }.map { |p| p.stone && p.stone.chain_id }.uniq.size
      end
    end

    describe 'with point adjacent to no chains' do
      it 'must not update the chains that are not adjacent' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 1, chain_id: 1 } },
          { id: 2, x: 2, y: 0, stone: { id: 3, player_number: 1, chain_id: 1 } },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: { id: 5, player_number: 1, chain_id: 1 } },
          { id: 5, x: 2, y: 1, stone: nil },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 2 } }
        ])

        point_id = 4
        point = point_set.points.find { |p| p.id == point_id }
        player_number = 1

        point_set.update_joined_chains(point_id, player_number)
        
        non_adjacent_point = point_set.points.find { |p| p.id == 8 }

        refute_equal point.stone.chain_id, non_adjacent_point.stone.chain_id
      end
    end
  end

  describe '#capture_stones' do
    describe 'with chains with no liberties' do
      it 'must remove those chains' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
          { id: 2, x: 2, y: 0, stone: nil },
          { id: 3, x: 0, y: 1, stone: { id: 3, player_number: 2, chain_id: 2 } },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: nil },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: nil }
        ])

        stone_count = point_set.capture_stones(2)
        captured_point = point_set.points.find { |p| p.id == 0 }

        refute captured_point.stone
        assert_equal 1, stone_count
      end
    end

    describe 'with chains with liberties' do
      it 'must not remove any chains' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
          { id: 2, x: 2, y: 0, stone: nil },
          { id: 3, x: 0, y: 1, stone: nil },
          { id: 4, x: 1, y: 1, stone: nil },
          { id: 5, x: 2, y: 1, stone: nil },
          { id: 6, x: 0, y: 2, stone: nil },
          { id: 7, x: 1, y: 2, stone: nil },
          { id: 8, x: 2, y: 2, stone: nil }
        ])

        point_set.capture_stones(2)
        points = point_set.points.select { |p| p.stone != nil }

        assert_equal 2, points.size 
      end
    end
  end

  describe '#minify' do
    it 'must return a string representing the board state' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
        { id: 2, x: 2, y: 0, stone: nil },
        { id: 3, x: 0, y: 1, stone: nil },
        { id: 4, x: 1, y: 1, stone: { id: 3, player_number: 1, chain_id: 3 } },
        { id: 5, x: 2, y: 1, stone: { id: 4, player_number: 2, chain_id: 4 } },
        { id: 6, x: 0, y: 2, stone: nil },
        { id: 7, x: 1, y: 2, stone: nil },
        { id: 8, x: 2, y: 2, stone: nil }
      ])

      result = point_set.minify

      assert_equal '12--12---', result
    end
  end

  describe '#place' do
    it 'adds stone on to the point' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
        { id: 2, x: 2, y: 0, stone: nil },
        { id: 3, x: 0, y: 1, stone: nil },
        { id: 4, x: 1, y: 1, stone: { id: 3, player_number: 1, chain_id: 3 } },
        { id: 5, x: 2, y: 1, stone: { id: 4, player_number: 2, chain_id: 4 } },
        { id: 6, x: 0, y: 2, stone: nil },
        { id: 7, x: 1, y: 2, stone: nil },
        { id: 8, x: 2, y: 2, stone: nil }
      ])

      point_id = 3

      stone = JustGo::Stone.new(id: 5, player_number: 1, chain_id: 5)

      point_set.place(point_id, stone)

      placed_point = point_set.points.find { |p| p.id == point_id }

      assert_equal stone, placed_point.stone
    end
  end

  describe '#next_stone_id' do
    describe 'with not points occupied' do
      it 'must return 1' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil }
        ])
        assert_equal 1, point_set.next_stone_id
      end
    end

    describe 'with a point occupied' do
      it 'must return the max point id + 1' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil }
        ])
        assert_equal 2, point_set.next_stone_id
      end
    end
  end

  describe '#adjacent_chain_id' do
    describe 'with no stones adjacent' do
      it 'must return nil' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil }
        ])
        point = point_set.points.find { |p| p.id == 1 }
        player_number = 1

        assert_nil point_set.adjacent_chain_id(point, player_number)
      end
    end

    describe 'with stones adjacent' do
      it 'must return the adjacent chain id' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil }
        ])
        point = point_set.points.find { |p| p.id == 1 }
        player_number = 1

        assert_equal 1, point_set.adjacent_chain_id(point, player_number)
      end
    end 
  end

  describe '#next_chain_id' do
    describe 'with no occupied points' do
      it 'must return 1' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil }
        ])

        assert_equal 1, point_set.next_chain_id
      end
    end

    describe 'with an occupied point' do
      it 'must return the max chain id + 1' do
        point_set = JustGo::PointSet.new(points: [
          { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 1, x: 1, y: 0, stone: nil }
        ])

        assert_equal 2, point_set.next_chain_id
      end
    end
  end

  describe '#build_stone' do
    it 'must return a new stone with id and chain id set' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: nil }
      ])
      point = point_set.points.find { |p| p.id == 1 }
      player_number = 2

      stone = point_set.build_stone(point, player_number)
      
      assert_instance_of JustGo::Stone, stone
      assert_equal 2, stone.id
      assert_equal player_number, stone.player_number
      assert_equal 2, stone.chain_id
    end
  end

  describe '#perform_move' do
    before do
      @point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
        { id: 2, x: 2, y: 0, stone: nil },
        { id: 3, x: 0, y: 1, stone: nil },
        { id: 4, x: 1, y: 1, stone: { id: 3, player_number: 2, chain_id: 2 } },
        { id: 5, x: 2, y: 1, stone: nil },
        { id: 6, x: 0, y: 2, stone: nil },
        { id: 7, x: 1, y: 2, stone: nil },
        { id: 8, x: 2, y: 2, stone: nil }
      ])
      @point = @point_set.points.find { |p| p.id == 3 }
      @player_number = 2
    end

    it 'places a stone' do
      @point_set.perform_move(@point, @player_number)
      placed_point = @point_set.points.find { |p| p.id == 3 }
      stone = placed_point.stone 

      assert_instance_of JustGo::Stone, stone
    end

    it 'updates chains' do
      @point_set.perform_move(@point, @player_number)
      chain_points = @point_set.points.select { |p| p.stone && p.stone.chain_id == 2 }

      assert_equal 3, chain_points.size
    end

    it 'captures stones' do
      @point_set.perform_move(@point, @player_number)

      capture_point = @point_set.points.find { |p| p.id == 0 }
      stone = capture_point.stone 

      assert_nil stone
    end

    it 'returns captured stone count' do
      result = @point_set.perform_move(@point, @player_number)

      assert_equal 1, result
    end
  end

  describe '#dup' do
    it 'must return a copy of the point set' do
      point_set = JustGo::PointSet.new(points: [
        { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
        { id: 1, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 2 } },
        { id: 2, x: 2, y: 0, stone: nil },
        { id: 3, x: 0, y: 1, stone: nil },
        { id: 4, x: 1, y: 1, stone: { id: 3, player_number: 2, chain_id: 2 } },
        { id: 5, x: 2, y: 1, stone: nil },
        { id: 6, x: 0, y: 2, stone: nil },
        { id: 7, x: 1, y: 2, stone: nil },
        { id: 8, x: 2, y: 2, stone: nil }
      ])

      dupped = point_set.dup
      refute_equal point_set.object_id, dupped.object_id
      assert_equal point_set.points, dupped.points
    end
  end
end
