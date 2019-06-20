module JustGo
  
  # = Game State
  # 
  # Represents a game of Go in progress.
  class GameState
    def initialize(current_player_number: , points: )
      @current_player_number = current_player_number
      @points = points
      @errors = []
      @last_change = {}
    end

    attr_reader :current_player_number 
    attr_reader :points
    attr_reader :errors 
    attr_reader :last_change 
  end
end
