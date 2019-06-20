module JustGo

  # = Stone
  # 
  # A stone that is placed on the board.
  class Stone
    def initialize(id: , player_number: )
      @id = id
      @player_number = player_number
    end
  end

  attr_reader :id
  attr_reader :player_number
end
