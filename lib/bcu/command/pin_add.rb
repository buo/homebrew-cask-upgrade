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
        return run_add_pin(cask_name) if $stdout.tty?

        redirect_stdout($stderr) do
          run_add_pin(cask_name)
        end
      end

      def run_add_pin(cask_name)
        if Pin.pinned.include? cask_name
          puts "Already pinned: #{Tty.green}#{cask_name}#{Tty.reset}"
          return
        end

        cask = Cask.load_cask cask_name

        File.open(PINS_FILE, "a") do |f|
          f.puts(cask_name)
        end

        formatted_cask_name = "#{Tty.green}#{cask_name}#{Tty.reset}"
        formatted_version = "#{Tty.magenta}#{cask.current}#{Tty.reset}"

        puts "Pinned: #{formatted_cask_name} in version #{formatted_version}"
      end
    end
  end
end
