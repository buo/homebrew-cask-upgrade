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

    if options.command == "pinned"
      Bcu::Pin::List.process
      return
    end

    if options.command == "pin"
      Bcu::Pin::Add.process args, options
      return
    end

    if options.command == "unpin"
      Bcu::Pin::Remove.process args, options
      return
    end

    Bcu::Upgrade.process options
  end

  private_class_method

  def self.load_commands
    commands = Dir[File.join(__dir__, "bcu/command", "*.rb")].sort
    commands.each { |file| require file }
  end
end
