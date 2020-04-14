require 'bcu/module/pin'

module Bcu
  module Pin
    class Add
      def self.process(args, options)
        pin = args[1]
        # TODO: If we used deprecated --pin option, the value is not any more in the args
        pin = options.pin if pin.nil?

        add_pin pin
      end

      private

      def self.add_pin(cask_name)
        if Pin::pinned.include? cask_name
          puts "Already pinned: #{Tty.send("green")}#{cask_name}#{Tty.reset}"
          return
        end

        cask = Cask.load_cask cask_name

        File.open(PINS_FILE, "a") do |f|
          f.puts(cask_name)
        end

        puts "Pinned: #{Tty.send("green")}#{cask_name}#{Tty.reset} in version #{Tty.send("magenta")}#{cask.version.to_s}#{Tty.reset}"
      end
    end
  end
end
