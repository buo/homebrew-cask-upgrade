# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Add < Command
      def process(args, options)
        pin = args[1]
        # TODO: If we used deprecated --pin option, the value is not any more in the args
        pin = options.pin if pin.nil?

        exit 1 unless Pin.pin(pin)
      end
    end
  end
end
