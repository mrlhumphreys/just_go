require 'just_go/errors/error'

module JustGo

  # = NotPlayersTurnError
  #
  # A not players turn error with a message
  class NotPlayersTurnError < Error

    # New not players turn errors can be instantiated with
    #
    # @option [String] message
    #   the message to display.
    #
    # ==== Example:
    #   # Instantiates a new NotPlayersTurnError
    #   JustGo::NotPlayersTurnError.new("Custom Message")
    def initialize(message="It is not the player's turn yet.") 
      super
    end
  end
end
