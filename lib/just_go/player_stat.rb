module JustGo
  # = PlayerStat
  # 
  # Place to store a players statistics
  class PlayerStat
    def initialize(player_number: , prisoner_count: 0, passed: false)
      @player_number = player_number
      @prisoner_count = prisoner_count
      @passed = passed
    end

    attr_reader :player_number
    attr_reader :prisoner_count
    attr_reader :passed

    def as_json
      {
        player_number: player_number,
        prisoner_count: prisoner_count,
        passed: passed
      }
    end

    def mark_as_passed 
      @passed = true
    end

    def mark_as_continuing 
      @passed = false
    end

    def add_to_prisoner_count(number)
      @prisoner_count += number
    end
  end
end
