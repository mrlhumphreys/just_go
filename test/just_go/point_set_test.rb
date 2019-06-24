require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/point_set'
require 'just_go/point'
require 'just_go/stone'

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

  describe '#adjacent' do
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

      result = point_set.adjacent(4)

      assert_equal [1, 3, 5, 7], result.points.map(&:id)
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
end
