require 'minitest/autorun'
require 'minitest/spec'
require 'just_go/chain'
require 'just_go/point'

describe JustGo::Chain do
  describe 'initialize' do
    it 'must set attributes' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3})
      chain = JustGo::Chain.new(points: [point])
      assert_equal [point], chain.points
    end
  end

  describe '#include?' do
    describe 'when point is in chain' do
      it 'must return true' do
        in_point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3})
        chain = JustGo::Chain.new(points: [in_point])

        assert chain.include?(in_point)
      end
    end

    describe 'when point is not in chain' do
      it 'must return false' do
        in_point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: 3})
        out_point = JustGo::Point.new(id: 2, x: 3, y: 4, stone: { id: 2, player_number: 3, chain_id: 4})
        chain = JustGo::Chain.new(points: [in_point])

        refute chain.include?(out_point)
      end
    end
  end

  describe '#player_number' do
    it 'must return the player number of the stone in the chain' do
      point_a = JustGo::Point.new(id: 1, x: 0, y: 0, stone: { id: 1, player_number: 2, chain_id: 3})
      point_b = JustGo::Point.new(id: 2, x: 1, y: 0, stone: { id: 2, player_number: 2, chain_id: 3})
      chain = JustGo::Chain.new(points: [point_a, point_b])

      assert_equal 2, chain.player_number
    end
  end
end
