# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  module Pin
    class Load < Command
      include Utils::Output::Mixin

      def process(_, options)
        file_name = options.backup_filename
        failed = Pin.read_tokens(file_name).reject { |token| Pin.pin(token) }
        odie "Failed to pin: #{failed.join(", ")}" unless failed.empty?

        puts Formatter.success "Pins loaded from #{file_name}"
      end
    end
  end
end
