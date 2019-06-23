require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/game_state'
require 'just_go/point_set'

describe JustGo::GameState do
  describe 'initialize' do
    it 'must set attributes' do
      game_state = JustGo::GameState.new(
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }
        ]
      )
      assert_equal 1, game_state.current_player_number
      assert_instance_of JustGo::PointSet, game_state.points
    end

    it 'must default errors and last_change' do
      game_state = JustGo::GameState.new(current_player_number: 1, points: [])
      assert_equal [], game_state.errors
      assert_equal({}, game_state.last_change)
    end
  end

  describe 'default' do
    it 'must return with a blank board state' do
      game_state = JustGo::GameState.default
      points = game_state.points.points
      assert_equal 1, game_state.current_player_number
      assert_equal 19*19, points.size
      assert_equal 19*19, points.map(&:id).uniq.size
      assert_equal 19, points.map(&:x).uniq.size
      assert_equal 19, points.map(&:y).uniq.size
      assert points.map(&:stone).all?(&:nil?)
    end
  end

  describe 'as_json' do
    it 'must return a hash of attributes' do
      game_state = JustGo::GameState.new(
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }
        ]
      )
      result = game_state.as_json
      expected = {
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: nil } }
        ]
      }
      assert_equal expected, result
    end
  end

  describe 'move' do

  end

end
