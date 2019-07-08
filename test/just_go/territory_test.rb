require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/territory'
require 'just_go/point'

describe JustGo::Territory do
  describe 'initialize' do
    it 'must set attributes' do
      point = JustGo::Point.new(id: 1, x: 2, y: 3, stone: nil, territory_id: 3)
      territory = JustGo::Territory.new(points: [point])
      assert_equal [point], territory.points
    end
  end

end
