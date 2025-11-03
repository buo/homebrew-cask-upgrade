# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Remove < Command
      def process(args, options)
        pin = args[1]
        # TODO: If we used deprecated --pin option, the value is not any more in the args
        pin = options.unpin if pin.nil?

        remove_pin_instance pin
      end

      # Class method to remove a pin - can be called from other classes
      def self.remove_pin(cask)
        return run_remove_pin(cask) if $stdout.tty?

        redirect_stdout($stderr) do
          run_remove_pin(cask)
        end
      end

      private

      def remove_pin_instance(cask)
        self.class.remove_pin(cask)
      end

      def self.run_remove_pin(cask)
        unless Pin.pinned.include? cask
          puts "Not pinned: #{Tty.green}#{cask}#{Tty.reset}"
          return
        end

        Pin.pinned.delete(cask)

        File.open(PINS_FILE, "w") do |f|
          Pin.pinned.each do |csk|
            f.puts(csk)
          end
        end

        puts "Unpinned: #{Tty.green}#{cask}#{Tty.reset}"
      end
    end
  end
end
