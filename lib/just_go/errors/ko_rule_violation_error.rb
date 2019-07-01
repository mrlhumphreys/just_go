require 'just_go/errors/error'

module JustGo

  # = KoRuleViolationError
  #
  # A not players turn error with a message
  class KoRuleViolationError < Error

    # New not players turn errors can be instantiated with
    #
    # @option [String] message
    #   the message to display.
    #
    # ==== Example:
    #   # Instantiates a new KoRuleViolationError
    #   JustGo::KoRuleViolationError.new("Custom Message")
    def initialize(message="Move puts board in previous state") 
      super
    end
  end
end
