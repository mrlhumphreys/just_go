require 'minitest/spec'
require 'minitest/autorun'
require 'just_go/vector'

Position = Struct.new(:x, :y)

describe JustGo::Vector do
  describe '#magnitude' do
    describe 'with two positions with the same x co-ordinate' do
      it 'must return the absoluate distance between two y co-ordinates' do
        origin = Position.new(1, 4)
        destination = Position.new(1, 7)
        vector = JustGo::Vector.new(origin, destination)
        assert_equal 3, vector.magnitude
      end
    end

    describe 'with two positions with the same y co-ordinate' do
      it 'must return the absoluate distance between two x co-oridnates' do
        origin = Position.new(1, 1)
        destination = Position.new(3, 1)
        vector = JustGo::Vector.new(origin, destination)
        assert_equal 2, vector.magnitude
      end
    end

    describe 'with two positions with different x and y co-ordinates' do
      it 'must return nil' do
        origin = Position.new(1, 1)
        destination = Position.new(3, 3)
        vector = JustGo::Vector.new(origin, destination)
        assert_nil vector.magnitude
      end

    end
  end

  describe '#orthogonal?' do
    describe 'when sharing the same x or y co-ordinates' do
      it 'must return true' do
        origin = Position.new(3, 1)
        destination = Position.new(3, 3)
        vector = JustGo::Vector.new(origin, destination)
        assert vector.orthogonal? 
      end
    end

    describe 'when not sharing the same x and y co-ordinates' do
      it 'must return false' do
        origin = Position.new(1, 1)
        destination = Position.new(3, 3)
        vector = JustGo::Vector.new(origin, destination)
        refute vector.orthogonal? 
      end
    end
  end
end
