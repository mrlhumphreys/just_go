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
        player_stats: [ 
          { player_number: 1, passed: false, prisoner_count: 0 },
          { player_number: 2, passed: false, prisoner_count: 0 }
        ],
        previous_state: "w"
      )
      assert_equal 1, game_state.current_player_number
      assert_instance_of JustGo::PointSet, game_state.points
      assert_instance_of Array, game_state.player_stats
      assert_equal "w", game_state.previous_state
    end

    it 'must default errors and last_change' do
      game_state = JustGo::GameState.new(
        current_player_number: 1, 
        points: [], 
        player_stats: [
          { player_number: 1, prisoner_count: 0, passed: false },
          { player_number: 2, prisoner_count: 1, passed: false }
        ]
      )
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
      assert_equal 1, game_state.player_stats.first.player_number
      assert_equal 0, game_state.player_stats.first.prisoner_count
      refute game_state.player_stats.first.passed
      assert_equal 2, game_state.player_stats.last.player_number
      assert_equal 0, game_state.player_stats.last.prisoner_count
      refute game_state.player_stats.last.passed
    end
  end

  describe '#as_json' do
    it 'must return a hash of attributes' do
      game_state = JustGo::GameState.new(
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2 } }
        ],
        player_stats: [
          { player_number: 1, prisoner_count: 0, passed: false },
          { player_number: 2, prisoner_count: 0, passed: false }
        ]
      )
      result = game_state.as_json
      expected = {
        current_player_number: 1,
        points: [
          { id: 1, x: 2, y: 3, stone: { id: 1, player_number: 2, chain_id: nil }, territory_id: nil }
        ],
        previous_state: nil,
        player_stats: [
          { player_number: 1, prisoner_count: 0, passed: false },
          { player_number: 2, prisoner_count: 0, passed: false }
        ]
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
          player_stats: [
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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

    describe 'with other player passed' do
      it 'clears the passed state' do
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
            { id: 7, x: 1, y: 2, stone: { id: 2, player_number: 2, chain_id: 2 } },
            { id: 8, x: 2, y: 2, stone: { id: 1, player_number: 1, chain_id: 1 } }
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: true }
          ] 
        )
        player_number = 1
        other_player_number = 2
        point_id = 4

        game_state.move(player_number, point_id)

        refute game_state.player_stats.detect { |ps| ps.player_number == other_player_number }.passed
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
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
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
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
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
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
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
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
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
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
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
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 0 }
          ]
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
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 1 }
          ]
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
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 0 }
          ]
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
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 0 }
          ]
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
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 0 }
          ]
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
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: false }
          ]
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

        prisoner_count = @game_state.player_stats.detect { |ps| ps.player_number == 2 }.prisoner_count

        assert_equal 1, prisoner_count 
      end
    end

    describe 'move puts board to previous position' do
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
            { id: 6, x: 1, y: 1, stone: nil },
            { id: 7, x: 2, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: { id: 5, player_number: 2, chain_id: 5 } },
            { id: 9, x: 4, y: 1, stone: nil },

            { id: 10, x: 0, y: 2, stone: nil },
            { id: 11, x: 1, y: 2, stone: { id: 2, player_number: 1, chain_id: 2 } },
            { id: 12, x: 2, y: 2, stone: nil },
            { id: 13, x: 3, y: 2, stone: { id: 3, player_number: 1, chain_id: 3 } },
            { id: 14, x: 4, y: 2, stone: { id: 6, player_number: 2, chain_id: 6 } },

            { id: 15, x: 0, y: 3, stone: nil },
            { id: 16, x: 1, y: 3, stone: nil },
            { id: 17, x: 2, y: 3, stone: { id: 4, player_number: 1, chain_id: 4 } },
            { id: 18, x: 3, y: 3, stone: { id: 7, player_number: 2, chain_id: 7 } },
            { id: 19, x: 4, y: 3, stone: nil },

            { id: 20, x: 0, y: 4, stone: nil },
            { id: 21, x: 1, y: 4, stone: nil },
            { id: 22, x: 2, y: 4, stone: nil },
            { id: 23, x: 3, y: 4, stone: nil },
            { id: 24, x: 4, y: 4, stone: nil }
          ],
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 0 },
            { player_number: 2, passed: false, prisoner_count: 0 }
          ],
          previous_state: '-------12--12-2--12------' 
        )
        @point_id = 12
        @player_number = 2
      end

      it 'must not place stone' do
        @game_state.move(@player_number, @point_id)

        point = @game_state.points.points.find { |p| p.id == @point_id }

        assert_nil point.stone
      end

      it 'must add error' do
        @game_state.move(@player_number, @point_id)

        error = @game_state.errors.first

        assert_instance_of JustGo::KoRuleViolationError, error 
      end

      it 'must return false' do
        result = @game_state.move(@player_number, @point_id)

        refute result
      end
    end
  end

  describe '#pass' do
    before do
      @game_state = JustGo::GameState.new(
        current_player_number: 1,
        points: [
          { id: 0, x: 0, y: 0, stone: nil },
          { id: 1, x: 1, y: 0, stone: nil },
          { id: 2, x: 2, y: 0, stone: nil },

          { id: 3, x: 3, y: 0, stone: nil },
          { id: 4, x: 4, y: 0, stone: nil },
          { id: 5, x: 0, y: 1, stone: nil },

          { id: 6, x: 1, y: 1, stone: nil },
          { id: 7, x: 2, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
          { id: 8, x: 3, y: 1, stone: { id: 5, player_number: 2, chain_id: 5 } },
        ],
        previous_state: nil,
        player_stats: [ 
          { player_number: 1, prisoner_count: 0, passed: false },
          { player_number: 2, prisoner_count: 0, passed: false }
        ]
      )
      @player_number = 1 
      @other_player_number = 2
    end

    describe 'when players turn' do
      it 'records that the player has passed' do
        @game_state.pass(@player_number)
        assert @game_state.player_stats.detect { |ps| ps.player_number == @player_number }.passed
      end

      it 'passes the turn' do
        @game_state.pass(@player_number)
        assert_equal @other_player_number, @game_state.current_player_number
      end

      it 'does not add error' do
        @game_state.pass(@player_number)
        error = @game_state.errors.first
        refute error 
      end

      it 'returns true' do
        result = @game_state.pass(@player_number)
        assert result
      end
    end

    describe 'when not players turn' do
      it 'does not record that the player has passed' do
        @game_state.pass(@other_player_number)
        refute @game_state.player_stats.detect { |ps| ps.player_number == @other_player_number }.passed
      end

      it 'does not pass the turn' do
        @game_state.pass(@other_player_number)
        assert_equal @player_number, @game_state.current_player_number
      end

      it 'adds error' do
        @game_state.pass(@other_player_number)
        error = @game_state.errors.first
        assert_instance_of JustGo::NotPlayersTurnError, error
      end

      it 'returns false' do
        result = @game_state.pass(@other_player_number)
        refute result
      end
    end

    describe 'when the other player has passed already' do
      before do
        @game_state = JustGo::GameState.new(
          current_player_number: 1,
          points: [
            { id: 0, x: 0, y: 0, stone: nil },
            { id: 1, x: 1, y: 0, stone: nil },
            { id: 2, x: 2, y: 0, stone: nil },

            { id: 3, x: 3, y: 0, stone: nil },
            { id: 4, x: 4, y: 0, stone: nil },
            { id: 5, x: 0, y: 1, stone: nil },

            { id: 6, x: 1, y: 1, stone: nil },
            { id: 7, x: 2, y: 1, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: { id: 5, player_number: 2, chain_id: 5 } },
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 0, passed: false },
            { player_number: 2, prisoner_count: 0, passed: true }
          ],
          previous_state: nil 
        )

        @player_number = 1 
      end

      it 'must not pass turn' do
        @game_state.pass(@player_number)

        assert_equal @player_number, @game_state.current_player_number
      end 

      it 'must mark territory' do
        @game_state.pass(@player_number)

        assert @game_state.points.points.any?(&:territory_id)
      end
    end
  end

  describe '#score' do
    describe 'with territory on the edge' do
      it 'counts the territory in the score' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil, territory_id: 1 },
            { id: 1, x: 1, y: 0, stone: nil, territory_id: 1 },
            { id: 2, x: 2, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 3, x: 3, y: 0, stone: nil, territory_id: 2 },
            { id: 4, x: 4, y: 0, stone: nil, territory_id: 2 },

            { id: 5, x: 0, y: 1, stone: nil, territory_id: 1 },
            { id: 6, x: 1, y: 1, stone: { id: 2, player_number: 1, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 3, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: nil, territory_id: 2 },
            { id: 9, x: 4, y: 1, stone: nil, territory_id: 2 },

            { id: 10, x: 0, y: 2, stone: { id: 4, player_number: 1, chain_id: 1 } },
            { id: 11, x: 1, y: 2, stone: { id: 5, player_number: 1, chain_id: 1 } },
            { id: 12, x: 2, y: 2, stone: nil, territory_id: 3 },
            { id: 13, x: 3, y: 2, stone: { id: 6, player_number: 2, chain_id: 2 } },
            { id: 14, x: 4, y: 2, stone: { id: 7, player_number: 2, chain_id: 2 } },

            { id: 15, x: 0, y: 3, stone: nil, territory_id: 4 },
            { id: 16, x: 1, y: 3, stone: nil, territory_id: 4 },
            { id: 17, x: 2, y: 3, stone: { id: 8, player_number: 2, chain_id: 2 } },
            { id: 18, x: 3, y: 3, stone: { id: 9, player_number: 2, chain_id: 2 } },
            { id: 19, x: 4, y: 3, stone: nil, territory_id: 5 },

            { id: 20, x: 0, y: 4, stone: nil, territory_id: 4 },
            { id: 21, x: 1, y: 4, stone: nil, territory_id: 4 },
            { id: 22, x: 2, y: 4, stone: { id: 10, player_number: 2, chain_id: 2 } },
            { id: 23, x: 3, y: 4, stone: nil, territory_id: 5 },
            { id: 24, x: 4, y: 4, stone: nil, territory_id: 5 }
          ],
          previous_state: nil,
          player_stats: [ 
            { player_number: 1, passed: false, prisoner_count: 4 },
            { player_number: 2, passed: false, prisoner_count: 2 }
          ]
        )

        result = game_state.score
        expected = [
          { player_number: 1, score: 7 },
          { player_number: 2, score: 5 }
        ]
        assert_equal(expected, result)
      end
    end
  end

  describe '#winner' do
    describe 'when both players have passed' do
      it 'must return the player with the highest score' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil, territory_id: 1 },
            { id: 1, x: 1, y: 0, stone: nil, territory_id: 1 },
            { id: 2, x: 2, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 3, x: 3, y: 0, stone: nil, territory_id: 2 },
            { id: 4, x: 4, y: 0, stone: nil, territory_id: 2 },

            { id: 5, x: 0, y: 1, stone: nil, territory_id: 1 },
            { id: 6, x: 1, y: 1, stone: { id: 2, player_number: 1, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 3, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: nil, territory_id: 2 },
            { id: 9, x: 4, y: 1, stone: nil, territory_id: 2 },

            { id: 10, x: 0, y: 2, stone: { id: 4, player_number: 1, chain_id: 1 } },
            { id: 11, x: 1, y: 2, stone: { id: 5, player_number: 1, chain_id: 1 } },
            { id: 12, x: 2, y: 2, stone: nil, territory_id: 3 },
            { id: 13, x: 3, y: 2, stone: { id: 6, player_number: 2, chain_id: 2 } },
            { id: 14, x: 4, y: 2, stone: { id: 7, player_number: 2, chain_id: 2 } },

            { id: 15, x: 0, y: 3, stone: nil, territory_id: 4 },
            { id: 16, x: 1, y: 3, stone: nil, territory_id: 4 },
            { id: 17, x: 2, y: 3, stone: { id: 8, player_number: 2, chain_id: 2 } },
            { id: 18, x: 3, y: 3, stone: { id: 9, player_number: 2, chain_id: 2 } },
            { id: 19, x: 4, y: 3, stone: nil, territory_id: 5 },

            { id: 20, x: 0, y: 4, stone: nil, territory_id: 4 },
            { id: 21, x: 1, y: 4, stone: nil, territory_id: 4 },
            { id: 22, x: 2, y: 4, stone: { id: 10, player_number: 2, chain_id: 2 } },
            { id: 23, x: 3, y: 4, stone: nil, territory_id: 5 },
            { id: 24, x: 4, y: 4, stone: nil, territory_id: 5 }
          ],
          player_stats: [ 
            { player_number: 1, prisoner_count: 4, passed: true },
            { player_number: 2, prisoner_count: 2, passed: true }
          ],
          previous_state: nil 
        )

        assert_equal 1, game_state.winner
      end
    end

    describe 'when both players have not passed' do
      it 'must return nil' do
        game_state = JustGo::GameState.new(
          current_player_number: 2,
          points: [
            { id: 0, x: 0, y: 0, stone: nil, territory_id: 1 },
            { id: 1, x: 1, y: 0, stone: nil, territory_id: 1 },
            { id: 2, x: 2, y: 0, stone: { id: 1, player_number: 1, chain_id: 1 } },
            { id: 3, x: 3, y: 0, stone: nil, territory_id: 2 },
            { id: 4, x: 4, y: 0, stone: nil, territory_id: 2 },

            { id: 5, x: 0, y: 1, stone: nil, territory_id: 1 },
            { id: 6, x: 1, y: 1, stone: { id: 2, player_number: 1, chain_id: 1 } },
            { id: 7, x: 2, y: 1, stone: { id: 3, player_number: 1, chain_id: 1 } },
            { id: 8, x: 3, y: 1, stone: nil, territory_id: 2 },
            { id: 9, x: 4, y: 1, stone: nil, territory_id: 2 },

            { id: 10, x: 0, y: 2, stone: { id: 4, player_number: 1, chain_id: 1 } },
            { id: 11, x: 1, y: 2, stone: { id: 5, player_number: 1, chain_id: 1 } },
            { id: 12, x: 2, y: 2, stone: nil, territory_id: 3 },
            { id: 13, x: 3, y: 2, stone: { id: 6, player_number: 2, chain_id: 2 } },
            { id: 14, x: 4, y: 2, stone: { id: 7, player_number: 2, chain_id: 2 } },

            { id: 15, x: 0, y: 3, stone: nil, territory_id: 4 },
            { id: 16, x: 1, y: 3, stone: nil, territory_id: 4 },
            { id: 17, x: 2, y: 3, stone: { id: 8, player_number: 2, chain_id: 2 } },
            { id: 18, x: 3, y: 3, stone: { id: 9, player_number: 2, chain_id: 2 } },
            { id: 19, x: 4, y: 3, stone: nil, territory_id: 5 },

            { id: 20, x: 0, y: 4, stone: nil, territory_id: 4 },
            { id: 21, x: 1, y: 4, stone: nil, territory_id: 4 },
            { id: 22, x: 2, y: 4, stone: { id: 10, player_number: 2, chain_id: 2 } },
            { id: 23, x: 3, y: 4, stone: nil, territory_id: 5 },
            { id: 24, x: 4, y: 4, stone: nil, territory_id: 5 }
          ],
          player_stats: [ 
            { player_number: 1, passed: true, prisoner_count: 4 },
            { player_number: 2, passed: false, prisoner_count: 2 }
          ],
          previous_state: nil 
        )

        assert_nil game_state.winner
      end
    end
  end
end
