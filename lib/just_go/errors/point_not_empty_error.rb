require 'just_go/errors/error'

module JustGo

  # = PointNotEmptyError
  #
  # A point not empty error with a message
  class PointNotEmptyError < Error

    # New not players turn errors can be instantiated with
    #
    # @option [String] message
    #   the message to display.
    #
    # ==== Example:
    #   # Instantiates a new PointNotEmptyError
    #   JustGo::PointNotEmptyError.new("Custom Message")
    def initialize(message="Point is not empty") 
      super
    end
  end
end
