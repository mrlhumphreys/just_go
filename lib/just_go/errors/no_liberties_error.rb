require 'just_go/errors/error'

module JustGo

  # = NoLibertiesError
  #
  # A not players turn error with a message
  class NoLibertiesError < Error

    # New not players turn errors can be instantiated with
    #
    # @option [String] message
    #   the message to display.
    #
    # ==== Example:
    #   # Instantiates a new NoLibertiesError
    #   JustGo::NoLibertiesError.new("Custom Message")
    def initialize(message="Point has no liberties") 
      super
    end
  end
end
