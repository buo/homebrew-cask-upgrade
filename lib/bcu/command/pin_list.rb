# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class List < Command
      def process(_args, _options)
        list_pinned
      end

      private

      def list_pinned
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
