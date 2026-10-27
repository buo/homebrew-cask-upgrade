# frozen_string_literal: true

module Bcu
  module Pin
    class List < Command
      def process(_args, _options)
        exit 1 unless system HOMEBREW_BREW_FILE.to_s, "list", "--pinned", "--cask", "--versions"
      end
    end
  end
end
