# frozen_string_literal: true

require "bcu/compat"

module Bcu
  # Cask pinning is delegated to Homebrew's native `brew pin --cask`.
  module Pin
    extend Utils::Output::Mixin

    # Pin list kept by brew cu before Homebrew supported pinning casks.
    LEGACY_PINS_FILE = File.expand_path("#{File.dirname(__FILE__)}/../../../pinned").freeze

    module_function

    # @return [Boolean] whether brew pinned the cask
    def pin(token)
      system HOMEBREW_BREW_FILE.to_s, "pin", "--cask", token
    end

    # @return [Boolean] whether brew unpinned the cask
    def unpin(token)
      system HOMEBREW_BREW_FILE.to_s, "unpin", "--cask", token
    end

    # @return [Array<String>] tokens of the pinned casks
    def pinned_tokens
      SystemCommand.run!(HOMEBREW_BREW_FILE, args: %w[list --pinned --cask]).stdout.split("\n")
    end

    # @return [Array<String>] cask tokens listed one per line in the file
    def read_tokens(file_name)
      File.readlines(file_name).map(&:strip).reject(&:empty?)
    end

    # Moves casks pinned through the legacy pin list to Homebrew's native pins
    # and removes the list, so this only ever runs once.
    def migrate_legacy_pins
      return unless File.exist?(LEGACY_PINS_FILE)

      tokens = read_tokens(LEGACY_PINS_FILE)
      if tokens.empty?
        File.delete(LEGACY_PINS_FILE)
        return
      end

      return run_migrate_legacy_pins(tokens) if $stdout.tty?

      Bcu::Compat.redirect_stdout($stderr) do
        run_migrate_legacy_pins(tokens)
      end
    end

    def run_migrate_legacy_pins(tokens)
      ohai "Migrating brew cu pins to Homebrew's native cask pinning"
      puts "brew cu now uses `brew pin --cask`, so pinned casks are also skipped by `brew upgrade`."

      migrated, failed = tokens.partition { |token| pin(token) }
      File.delete(LEGACY_PINS_FILE)

      unless migrated.empty?
        ohai "Migrated #{::Utils.pluralize("pinned cask", migrated.length, include_count: true)}: " \
             "#{migrated.join(", ")}"
      end
      return if failed.empty?

      opoo "Could not pin #{::Utils.pluralize("cask", failed.length, include_count: true)} (see above), " \
           "pin again with `brew cu pin <cask>` once installed: #{failed.join(", ")}"
    end
    private_class_method :run_migrate_legacy_pins
  end
end
