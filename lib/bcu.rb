$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "cask/all"
require "extend/formatter"
require "extend/cask"
require "fileutils"
require "set"
require "shellwords"

module Bcu
  def self.process(args)
    # Load all commands
    load_commands
    parse!(args)

    command = resolve_command options
    command.process args, options
  end

  def self.load_commands
    commands = Dir[File.join(__dir__, "bcu/command", "*.rb")].sort
    commands.each { |file| require file }
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
