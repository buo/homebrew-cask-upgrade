# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Add < Command
      def process(args, options)
        pin = args[1]
        # TODO: If we used deprecated --pin option, the value is not any more in the args
        pin = options.pin if pin.nil?

        add_pin pin
      end

      private

      def add_pin(cask_name)
        if Pin.pinned.include? cask_name
          puts_stdout_or_stderr "Already pinned: #{Tty.green}#{cask_name}#{Tty.reset}"
          return
        end

        cask = Cask.load_cask cask_name

        File.open(PINS_FILE, "a") do |f|
          f.puts(cask_name)
        end

        formatted_cask_name = "#{Tty.green}#{cask_name}#{Tty.reset}"
        formatted_version = "#{Tty.magenta}#{cask.version}#{Tty.reset}"

        puts_stdout_or_stderr "Pinned: #{formatted_cask_name} in version #{formatted_version}"
      end
    end
  end
end
