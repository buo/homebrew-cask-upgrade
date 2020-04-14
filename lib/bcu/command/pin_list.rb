require 'bcu/module/pin'

module Bcu
  module Pin
    class List
      def self.process
        list_pinned
      end

      private

      def self.list_pinned
        casks = []
        Pin::pinned.each do |cask_name|
          begin
            casks.push Cask.load_cask(cask_name)
          rescue Cask::CaskUnavailableError
            Bcu::Pin::Remove.remove_pin cask_name
          end
        end

        Formatter.print_pin_table casks unless casks.empty?
      end
    end
  end
end
