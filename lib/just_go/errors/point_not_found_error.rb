require 'just_go/errors/error'

module JustGo

  # = PointNotFoundError
  #
  # A point not found error with a message
  class PointNotFoundError < Error

    # New not players turn errors can be instantiated with
    #
    # @option [String] message
    #   the message to display.
    #
    # ==== Example:
    #   # Instantiates a new PointNotFoundError
    #   JustGo::PointNotFoundError.new("Custom Message")
    def initialize(message="Can't find point with that id") 
      super
    end
  end
end
