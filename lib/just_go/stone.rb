module JustGo

  # = Stone
  # 
  # A stone that is placed on the board.
  class Stone
    def initialize(id: , player_number: , chain_id: nil)
      @id = id
      @player_number = player_number
      @chain_id = chain_id
    end

    attr_reader :id
    attr_reader :player_number
    attr_reader :chain_id

    def as_json
      {
        id: id,
        player_number: player_number,
        chain_id: chain_id
      }
    end

    def join_chain(stone)
      @chain_id = stone.chain_id
    end
  end
end
