# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Export < Command
      def process(_, options)
        file_name = options.export_filename
        File.open(file_name, "w+") do |file|
          Pin.pinned.each do |cask_name|
            file.puts cask_name
          end
        end
        puts Formatter.success "Pins exported to #{file_name}"
      end
    end
  end
end
