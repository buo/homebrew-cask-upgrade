require "bcu/module/pin"

module Bcu
  module Pin
    class List < Command
      def process(args, options)
        list_pinned args, options
      end

      private

      def list_pinned(_args, _options)
        casks = []
        Pin.pinned.each do |cask_name|
          add_cask cask_name, casks
        end

        Formatter.print_pin_table casks unless casks.empty?
      end

      def add_cask(cask_name, casks)
        casks.push Cask.load_cask(cask_name)
      rescue Cask::CaskUnavailableError
        Bcu::Pin::Remove.remove_pin cask_name
      end
    end
  end
end
