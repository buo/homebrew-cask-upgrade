require "optparse"
require "ostruct"

module Bcu
  class << self; attr_accessor :options; end

  def self.parse!(args)
    options = OpenStruct.new
    options.all = false
    options.force = false
    options.casks = nil
    options.cleanup = false
    options.force_yes = false
    options.no_brew_update = false
    options.quiet = false
    options.install_options = ""
    options.list_pinned = false
    options.pin = nil
    options.unpin = nil
    options.interactive = false

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [CASK] [options]"

      opts.on("-a", "--all", "Include apps that auto-update in the upgrade") do
        options.all = true
      end

      opts.on("--cleanup", "Cleans up cached downloads and tracker symlinks after updating") do
        options.cleanup = true
      end

      opts.on("-f", "--force", "Include apps that are marked as latest (i.e. force-reinstall them)") do
        options.force = true
      end

      opts.on("--no-brew-update", "Prevent auto-update of Homebrew, taps, and formulae before checking outdated apps") do
        options.no_brew_update = true
      end

      opts.on("-y", "--yes", "Update all outdated apps; answer yes to updating packages") do
        options.force_yes = true
      end

      opts.on("-i", "--interactive", "Use interactive mode while installing") do
        options.interactive = true
      end

      opts.on("-q", "--quiet", "Do not show information about installed apps or current options") do
        options.quiet = true
      end

      opts.on("--no-quarantine", "Add --no-quarantine option to install command, see brew cask documentation for additional information") do
        options.install_options += " --no-quarantine"
      end

      opts.on("--pinned", "List pinned apps") do
        options.list_pinned = true
      end

      opts.on("--pin CASK", "Cask to pin") do |cask|
        options.pin = cask
      end

      opts.on("--unpin CASK", "Cask to unpin") do |cask|
        options.unpin = cask
      end
    end

    parser.parse!(args)

    options.casks = args

    self.options = options
  end
end
