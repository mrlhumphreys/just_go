require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/player_stat'

describe JustGo::PlayerStat do
  describe 'initialize' do
    it 'must set attributes' do
      player_stat = JustGo::PlayerStat.new(player_number: 1, prisoner_count: 0, passed: false)
      assert_equal 1, player_stat.player_number
      assert_equal 0, player_stat.prisoner_count
      refute player_stat.passed
    end
  end

  describe '#as_json' do
    it 'must return the attributes as a hash' do
      player_stat = JustGo::PlayerStat.new(player_number: 1, prisoner_count: 0, passed: false)
      result = player_stat.as_json
      expected = {
        player_number: 1,
        prisoner_count: 0,
        passed: false
      }
      assert_equal expected, result
    end
  end

  describe '#mark_as_passed' do
    it 'must set passed to true' do
      player_stat = JustGo::PlayerStat.new(player_number: 1, prisoner_count: 0, passed: false)
      player_stat.mark_as_passed
      assert player_stat.passed
    end
  end

  describe '#mark_as_continuing' do
    it 'must set passed to false' do
      player_stat = JustGo::PlayerStat.new(player_number: 1, prisoner_count: 0, passed: true)
      player_stat.mark_as_continuing
      refute player_stat.passed
    end
  end

  describe '#add_to_prisoner_count' do
    it 'must add that much to prisoner count' do
      player_stat = JustGo::PlayerStat.new(player_number: 1, prisoner_count: 1, passed: false)
      player_stat.add_to_prisoner_count(2)
      assert_equal 3, player_stat.prisoner_count
    end
  end
end
