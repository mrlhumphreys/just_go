module JustGo
  Vector = Struct.new(:origin, :destination) do
    def magnitude
      if dx.abs == 0
        dy.abs
      elsif dy.abs == 0
        dx.abs
      else
        nil 
      end
    end

    def orthogonal?
      dx == 0 || dy == 0
    end

    def dx
      destination.x - origin.x
    end

    def dy
      destination.y - origin.y
    end
  end
end
