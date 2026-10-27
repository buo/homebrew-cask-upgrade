# frozen_string_literal: true

$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "bcu/command/all"
require "bcu/module/pin"
# Causing following issue:
# Error: No such file or directory @ rb_sysopen
#  - /opt/homebrew/Library/Homebrew/vendor/bundle/ruby/2.6.0/gems/addressable-2.8.0/data/unicode.data
#
# https://github.com/buo/homebrew-cask-upgrade/issues/205
# require "cask"
require "extend/formatter"
require "extend/cask"
require "extend/version"
require "fileutils"
require "shellwords"

module Bcu
  def self.process(args)
    parse!(args)

    unless defined?(HOMEBREW_PINNED_CASKS)
      odie "brew cu requires Homebrew 5.1.12 or newer for cask pinning. Run `brew update` and try again."
    end
    Bcu::Pin.migrate_legacy_pins

    command = resolve_command options
    command.process args, options
  end

  # @param [Struct] options
  # @return [Command]
  def self.resolve_command(options)
    return Bcu::Pin::List.new if options.command == "pinned"
    return Bcu::Pin::Export.new if options.command == "export"
    return Bcu::Pin::Load.new if options.command == "load"
    return Bcu::Pin::Add.new if options.command == "pin"
    return Bcu::Pin::Remove.new if options.command == "unpin"
    return Bcu::Livecheck.new if options.command == "livecheck"

    Bcu::Upgrade.new
  end
end
