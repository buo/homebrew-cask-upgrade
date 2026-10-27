# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Export < Command
      def process(_, options)
        file_name = options.backup_filename
        File.write(file_name, Pin.pinned_tokens.map { |token| "#{token}\n" }.join)
        puts Formatter.success "Pins exported to #{file_name}"
      end
    end
  end
end
