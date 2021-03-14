# frozen_string_literal: true

$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "bcu/command/all"
require "cask"
require "extend/formatter"
require "extend/cask"
require "extend/version"
require "fileutils"
require "set"
require "shellwords"

module Bcu
  def self.process(args)
    parse!(args)

    command = resolve_command options
    command.process args, options
  end

  # @param [Struct] options
  # @return [Command]
  def self.resolve_command(options)
    return Bcu::Pin::List.new if options.command == "pinned"
    return Bcu::Pin::Add.new if options.command == "pin"
    return Bcu::Pin::Remove.new if options.command == "unpin"

    Bcu::Upgrade.new
  end
end
