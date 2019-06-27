require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/point'
require 'just_go/stone'

describe JustGo::Point do
  describe 'initialize' do
    it 'must set attributes' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
      assert_equal 1, point.id
      assert_equal 2, point.x
      assert_equal 3, point.y
      assert_nil point.stone
    end

    it 'must handle a hash of stone' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2})
      stone = point.stone
      assert_instance_of JustGo::Stone, stone
      assert_equal 1, stone.id
      assert_equal 2, stone.player_number
    end

    it 'must handle a stone object' do
      stone = JustGo::Stone.new(id: 1, player_number: 2)
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: stone)
      assert_equal stone, point.stone
    end

    it 'must handle a nil object' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
      assert_nil point.stone
    end

    it 'must raise error when stone is not hash stone or nil' do
      assert_raises ArgumentError do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: 4)
      end
    end
  end

  describe '#as_json' do
    it 'must return a hash of attributes' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2})
      result = point.as_json
      expected = {
        id: 1,
        x: 2,
        y: 3,
        stone: {
          id: 1,
          player_number: 2,
          chain_id: nil
        }
      }
      assert_equal expected, result
    end
  end

  describe '#place' do
    it 'must place a stone on the point' do
      stone = JustGo::Stone.new(id: 1, player_number: 2, chain_id: 3)
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
      point.place(stone)

      assert_instance_of JustGo::Stone, point.stone
      assert_equal stone.id, point.stone.id
    end
  end

  describe '#occupied?' do
    describe 'with a stone' do
      it 'must be true' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        assert point.occupied?
      end
    end

    describe 'without a stone' do
      it 'must be false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
        refute point.occupied?
      end
    end
  end

  describe '#unoccupied?' do
    describe 'without a stone' do
      it 'must be true' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
        assert point.unoccupied?
      end
    end

    describe 'with a stone' do
      it 'must be false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        refute point.unoccupied?
      end
    end
  end

  describe '#occupied_by?' do
    describe 'when occupied by the player' do
      it 'must return true' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        assert point.occupied_by?(2)
      end
    end

    describe 'when occupied by the other player' do
      it 'must return false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        refute point.occupied_by?(1)
      end
    end

    describe 'when not occupied' do
      it 'must return false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
        refute point.occupied_by?(1)
      end
    end
  end

  describe '#occupied_by_opponent?' do
    describe 'when occupied by the opponent' do
      it 'must return true' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        assert point.occupied_by_opponent?(1)
      end
    end

    describe 'when occupied by the player' do
      it 'must return false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3 })
        refute point.occupied_by_opponent?(2)
      end
    end

    describe 'when not occupied' do
      it 'must return false' do
        point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil)
        refute point.occupied_by?(1)
      end
    end
  end
end
