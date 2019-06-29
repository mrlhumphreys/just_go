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
        ],
        prisoner_counts: {
          1 => 0,
          2 => 0
        },
        previous_state: "w"
      )
      assert_equal 1, game_state.current_player_number
      assert_instance_of JustGo::PointSet, game_state.points
      assert_instance_of Hash, game_state.prisoner_counts
      assert_equal "w", game_state.previous_state
    end

    it 'must default errors and last_change' do
      game_state = JustGo::GameState.new(current_player_number: 1, points: [], prisoner_counts: { 1 => 0, 2 => 0 })
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
      assert_equal({ 1 => 0, 2 => 0 }, game_state.prisoner_counts)
    end
  end

  describe '#as_json' do
    it 'must return a hash of attributes' do
      game_state = JustGo::GameState.new(
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }
        ],
        prisoner_counts: {
          1 => 0,
          2 => 0
        }
      )
      result = game_state.as_json
      expected = {
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: nil } }
        ],
        prisoner_counts: {
          1 => 0,
          2 => 0
        },
        previous_state: nil
      }
      assert_equal expected, result
    end
  end

  describe '#move' do
    describe 'that is valid' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 0, y: 1, stone: nil },
            { id: 4, x: 1, y: 1, stone: nil },
            { id: 5, x: 2, y: 1, stone: nil },
            { id: 6, x: 0, y: 2, stone: nil },
            { id: 7, x: 1, y: 2, stone: { id: 2, player_number: 2, chain_id: 2 } },
            { id: 8, x: 2, y: 2, stone: { id: 1, player_number: 1, chain_id: 1 } }
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )
        @player_number = 1
        @point_id = 4
      end

      it 'places the stone' do
        @game_state.move(@player_number, @point_id)
        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone
        assert stone
        assert_equal @player_number, stone.player_number
      end

      it 'passes the turn' do
        @game_state.move(@player_number, @point_id)
        assert_equal 2, @game_state.current_player_number
      end

      it 'sets no errors' do
        @game_state.move(@player_number, @point_id)
        assert_empty @game_state.errors
      end

      it 'returns true' do
        result = @game_state.move(@player_number, @point_id)
        assert result
      end

      it 'stores the previous state' do
        @game_state.move(@player_number, @point_id)
        assert_equal '-------21', @game_state.previous_state
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        point_id = 7 
        game_state.move(1, point_id)

        stone = game_state.points.points.find { |p| p.id == point_id }.stone
        assert_equal 3, stone.chain_id
      end
    end

    describe 'when not on players turn' do
      before do
        @game_state = JustGo::GameState.new(
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        ) 
        @player_number = 1
        @point_id = 8 
      end

      it 'must not place a stone' do
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        refute stone
      end

      it 'must set an error' do
        @game_state.move(@player_number, @point_id)

        error = @game_state.errors.first

        assert_instance_of JustGo::NotPlayersTurnError, error 
      end

      it 'must not pass turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result 
      end
    end

    describe 'when point is occupied' do
      before do
        @game_state = JustGo::GameState.new(
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 1
          }
        )
        @player_number = 2 
        @point_id = 0 
      end

      it 'must not place a stone' do
        occupying_stone = @game_state.points.points.find { |p| p.id == @point_id }.stone
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        assert_equal stone, occupying_stone 
      end

      it 'must set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_instance_of JustGo::PointNotEmptyError, error
      end

      it 'must not pass turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result
      end
    end

    describe 'when point does not exist' do
      before do
        @game_state = JustGo::GameState.new(
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )
        @player_number = 2 
        @point_id = 999 
      end

      it 'must set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_instance_of JustGo::PointNotFoundError, error
      end

      it 'must not pass turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result
      end
    end

    describe 'when point is surrounded by opponent' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 3, y: 0, stone: nil },
            { id: 4, x: 4, y: 0, stone: nil },

            { id: 5, x: 0, y: 1, stone: nil },
            { id: 6, x: 1, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 2, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: { id: 3, player_number: 1, chain_id: 1 } },
            { id: 9, x: 4, y: 1, stone: nil },

            { id: 10, x: 0, y: 2, stone: nil },
            { id: 11, x: 1, y: 2, stone: { id: 4, player_number: 1, chain_id: 1 } },
            { id: 12, x: 2, y: 2, stone: nil },
            { id: 13, x: 3, y: 2, stone: { id: 5, player_number: 1, chain_id: 1 } },
            { id: 14, x: 4, y: 2, stone: nil },

            { id: 15, x: 0, y: 3, stone: nil },
            { id: 16, x: 1, y: 3, stone: { id: 6, player_number: 1, chain_id: 1 } },
            { id: 17, x: 2, y: 3, stone: { id: 7, player_number: 1, chain_id: 1 } },
            { id: 18, x: 3, y: 3, stone: { id: 8, player_number: 1, chain_id: 1 } },
            { id: 19, x: 4, y: 3, stone: nil },

            { id: 20, x: 0, y: 4, stone: nil },
            { id: 21, x: 1, y: 4, stone: nil },
            { id: 22, x: 2, y: 4, stone: nil },
            { id: 23, x: 3, y: 4, stone: nil },
            { id: 24, x: 4, y: 4, stone: nil },
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )
        @player_number = 2 
        @point_id = 12 
      end

      it 'must not place a stone' do
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        assert_nil stone 
      end 

      it 'must set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_instance_of JustGo::NoLibertiesError, error
      end

      it 'must not pass turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result
      end
    end

    describe 'when a point is surrounded and placing a stone deprives the chains liberties' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        @player_number = 2 
        @point_id = 12 
      end

      it 'must not place a stone' do
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        assert_nil stone 
      end

      it 'must set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_instance_of JustGo::NoLibertiesError, error
      end

      it 'must pass not turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result
      end
    end

    describe 'when a point is surrounded and placing a stone does not deprive the chains liberties' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 3, y: 0, stone: nil },
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        @player_number = 2 
        @point_id = 12 
      end

      it 'must place a stone' do
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        assert_instance_of JustGo::Stone, stone 
      end

      it 'must not set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_nil error
      end

      it 'must pass the turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 1, @game_state.current_player_number
      end

      it 'must return true' do
        result = @game_state.move(@player_number, @point_id)

        assert result
      end
    end

    describe 'when a point is surrounded and placing a stone deprives an opposing chains liberties' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
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
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        @player_number = 1 
        @point_id = 12 
      end

      it 'must place a stone' do
        @game_state.move(@player_number, @point_id)

        stone = @game_state.points.points.find { |p| p.id == @point_id }.stone

        assert_instance_of JustGo::Stone, stone 
      end

      it 'must not set an error' do
        @game_state.move(@player_number, @point_id)
        
        error = @game_state.errors.first

        assert_nil error
      end

      it 'must pass the turn' do
        @game_state.move(@player_number, @point_id)

        assert_equal 2, @game_state.current_player_number
      end

      it 'must return true' do
        result = @game_state.move(@player_number, @point_id)

        assert result
      end
    end

    describe 'move connects stones' do
      it 'joins them in one chain' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 3, y: 0, stone: nil },
            { id: 4, x: 4, y: 0, stone: nil },

            { id: 5, x: 0, y: 1, stone: nil },
            { id: 6, x: 1, y: 1, stone: { id: 1, player_number: 2, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 2, player_number: 2, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: { id: 3, player_number: 2, chain_id: 1 } },
            { id: 9, x: 4, y: 1, stone: nil },

            { id: 10, x: 0, y: 2, stone: nil },
            { id: 11, x: 1, y: 2, stone: nil },
            { id: 12, x: 2, y: 2, stone: nil },
            { id: 13, x: 3, y: 2, stone: nil },
            { id: 14, x: 4, y: 2, stone: nil },

            { id: 15, x: 0, y: 3, stone: nil },
            { id: 16, x: 1, y: 3, stone: { id: 4, player_number: 2, chain_id: 2 } },
            { id: 17, x: 2, y: 3, stone: { id: 5, player_number: 2, chain_id: 2 } },
            { id: 18, x: 3, y: 3, stone: { id: 6, player_number: 2, chain_id: 2 } },
            { id: 19, x: 4, y: 3, stone: nil },

            { id: 20, x: 0, y: 4, stone: nil },
            { id: 21, x: 1, y: 4, stone: nil },
            { id: 22, x: 2, y: 4, stone: nil },
            { id: 23, x: 3, y: 4, stone: nil },
            { id: 24, x: 4, y: 4, stone: nil }
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        player_number = 2 
        point_id = 12 

        game_state.move(player_number, point_id)

        points = game_state.points.points.select { |p| [6, 7, 8, 12, 16, 17, 18].include?(p.id) }
        assert_equal 1, points.map { |p| p.stone.chain_id }.uniq.size
      end
    end

    describe 'move surrounds stone' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },
            { id: 3, x: 3, y: 0, stone: nil },
            { id: 4, x: 4, y: 0, stone: nil },

            { id: 5, x: 0, y: 1, stone: nil },
            { id: 6, x: 1, y: 1, stone: { id: 1, player_number: 2, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 2, player_number: 2, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: { id: 3, player_number: 2, chain_id: 1 } },
            { id: 9, x: 4, y: 1, stone: nil },

            { id: 10, x: 0, y: 2, stone: nil },
            { id: 11, x: 1, y: 2, stone: { id: 7, player_number: 2, chain_id: 1 } },
            { id: 12, x: 2, y: 2, stone: { id: 8, player_number: 1, chain_id: 2 } },
            { id: 13, x: 3, y: 2, stone: nil },
            { id: 14, x: 4, y: 2, stone: nil },

            { id: 15, x: 0, y: 3, stone: nil },
            { id: 16, x: 1, y: 3, stone: { id: 4, player_number: 2, chain_id: 1 } },
            { id: 17, x: 2, y: 3, stone: { id: 5, player_number: 2, chain_id: 1 } },
            { id: 18, x: 3, y: 3, stone: { id: 6, player_number: 2, chain_id: 1 } },
            { id: 19, x: 4, y: 3, stone: nil },

            { id: 20, x: 0, y: 4, stone: nil },
            { id: 21, x: 1, y: 4, stone: nil },
            { id: 22, x: 2, y: 4, stone: nil },
            { id: 23, x: 3, y: 4, stone: nil },
            { id: 24, x: 4, y: 4, stone: nil }
          ],
          prisoner_counts: {
            1 => 0,
            2 => 0
          }
        )

        @player_number = 2 
        @point_id = 13 
      end

      it 'removes surrounded stone' do
        @game_state.move(@player_number, @point_id)

        capture_point = @game_state.points.points.find { |p| p.id == 12 } 

        refute capture_point.stone
      end

      it 'increments prisoner_counts' do
        @game_state.move(@player_number, @point_id)

        assert_equal 1, @game_state.prisoner_counts[2] 
      end
    end
  end
end
