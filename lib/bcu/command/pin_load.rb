# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Load < Command
      def process(_, options)
        file_name = options.export_filename
        File.open(file_name, "r") do |source_file|
          File.open PINS_FILE, "w+" do |file|
            source_file.each_line do |cask|
              file.puts(cask.rstrip)
            end
          end
        end
        puts Formatter.success "Pins loaded from #{file_name}"
      end
    end
  end
end
