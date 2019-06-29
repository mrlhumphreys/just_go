require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/stone'

describe JustGo::Stone do
  describe 'initialize' do
    it 'must set attributes' do
      stone = JustGo::Stone.new(id: 1, player_number: 2, chain_id: 3)
      assert_equal 1, stone.id
      assert_equal 2, stone.player_number
      assert_equal 3, stone.chain_id
    end

    it 'must default chain_id to nil' do
      stone = JustGo::Stone.new(id: 1, player_number: 2)
      assert_nil stone.chain_id
    end
  end

  describe '#as_json' do
    it 'must return a hash of attributes' do
      stone = JustGo::Stone.new(id: 1, player_number: 2, chain_id: 3)
      result = stone.as_json
      expected = {
        id: 1,
        player_number: 2,
        chain_id: 3
      } 
      assert_equal expected, result
    end
  end

  describe '#join_chain' do
    it 'must set the chain id to the passed in stone' do
      stone = JustGo::Stone.new(id: 1, player_number: 1, chain_id: 1)
      other_stone = JustGo::Stone.new(id: 2, player_number: 1, chain_id: 2)
      stone.join_chain(other_stone)
      assert_equal other_stone.chain_id, stone.chain_id
    end
  end
end
