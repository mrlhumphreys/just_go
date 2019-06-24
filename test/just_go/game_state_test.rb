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

  describe '.default' do
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

  describe '#as_json' do
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

  describe '#move' do
    describe 'that is valid' do
      it 'places the stone' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )
        player_number = 1
        point_id = 4
        game_state.move(player_number, point_id)
        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert stone
        assert_equal player_number, stone.player_number
      end

      it 'passes the turn' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        game_state.move(1, 4)
        assert_equal 2, game_state.current_player_number
      end

      it 'sets no errors' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        game_state.move(1, 4)

        assert_empty game_state.errors
      end

      it 'returns true' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        result = game_state.move(1, 4)

        assert result
      end
    end

    describe 'with no stones on the board' do
      it 'must place a stone with id 1' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        point_id = 4
        game_state.move(1, point_id)
        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 1, stone.id
      end

      it 'must place a stone with chain id 1' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        point_id = 4
        game_state.move(1, point_id)
        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 1, stone.chain_id
      end
    end

    describe 'with stones on the board' do
      it 'must place a stone with id max + 1' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        point_id = 4
        game_state.move(2, point_id)
        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 2, stone.id
      end
    end

    describe 'placed by itself' do
      it 'must place a stone with chain id max + 1' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: nil }
          ]
        )

        point_id = 4
        game_state.move(2, point_id)
        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 2, stone.chain_id
      end
    end

    describe 'placed next to others owned by the same player' do
      it 'must place a stone with chain id of the adjacent one' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: { id: 2, player_number: 2, chain_id: 2 } }
          ]
        )

        point_id = 1
        game_state.move(1, point_id)

        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 1, stone.chain_id
      end
    end

    describe 'placed next to others owned by different player' do
      it 'must place a stone with chain id max + 1' do
        game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: nil },
            { id: 8, x: 2, y: 2, stone: { id: 2, player_number: 2, chain_id: 2 } }
          ]
        )

        point_id = 7 
        game_state.move(1, point_id)

        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 3, stone.chain_id
      end
    end
  end
end
