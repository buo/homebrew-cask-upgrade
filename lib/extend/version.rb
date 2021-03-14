# frozen_string_literal: true

module Cask
  class DSL
    class Version
      def before_hyphen
        version { split("-", 2).first }
      end

      def after_hyphen
        version { split("-", 2).second }
      end

      def before_separators
        version { before_hyphen.before_colon.before_comma }
      end
    end
  end
end
