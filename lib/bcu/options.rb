# frozen_string_literal: true

require "optparse"

module Bcu
  class << self
    attr_accessor :options
  end

  def self.parse!(args)
    options_struct = Struct.new(:all, :force, :casks, :cleanup, :force_yes, :no_brew_update, :quiet, :verbose,
                                :install_options, :list_pinned, :pin, :unpin, :interactive, :command, :report_only,
                                :export_filename)
    options = options_struct.new
    options.all = false
    options.force = false
    options.casks = nil
    options.cleanup = false
    options.force_yes = false
    options.no_brew_update = false
    options.quiet = false
    options.verbose = false
    options.install_options = ""
    options.list_pinned = false
    options.pin = nil
    options.unpin = nil
    options.interactive = false
    options.report_only = false
    options.command = "run"
    options.export_filename = ""

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [CASK] [options]"

      # Prevent using short -p syntax for pinning
      opts.on("-p") do
        odie "invalid option -p, did you mean --pin?"
      end

      # Prevent using short -u syntax for unpinning
      opts.on("-u") do
        odie "invalid option -u, did you mean --unpin?"
      end

      opts.on("-a", "--all", "Include apps that auto-update in the upgrade") do
        options.all = true
      end

      opts.on("--cleanup", "Cleans up cached downloads and tracker symlinks after updating") do
        options.cleanup = true
      end

      opts.on("-f", "--force", "Include apps that are marked as latest (i.e. force-reinstall them)") do
        options.force = true
      end

      opts.on(
        "--no-brew-update",
        "Prevent auto-update of Homebrew, taps, and formulae before checking outdated apps",
      ) do
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

      opts.on("-v", "--verbose", "Make output more verbose") do
        options.verbose = true
      end

      opts.on(
        "--no-quarantine",
        "Add --no-quarantine option to install command, see brew cask documentation for additional information",
      ) do
        options.install_options += " --no-quarantine"
      end

      opts.on("--pinned", "List pinned apps") do
        onoe "Using option --pinned for listing pinned apps is deprecated, please use \"brew cu pinned\" command."
        options.command = "pinned"
      end

      opts.on("--pin CASK", "Cask to pin") do |cask|
        onoe "Using option --pin for pinning is deprecated, please use \"brew cu pin\" command."
        options.command = "pin"
        options.pin = cask
      end

      opts.on("--unpin CASK", "Cask to unpin") do |cask|
        onoe "Using option --unpin for unpinning is deprecated, please use \"brew cu unpin\" command."
        options.unpin = cask
        options.command = "unpin"
      end

      opts.on("--report-only", "Only report casks to update with exit code") do
        options.report_only = true
      end

      if args[0] == "pinned"
        opts.on("--export FILENAME", "Filename for export") do |filename|
          options.export_filename = filename
          options.command = "export"
        end

        opts.on("--load FILENAME", "Source filename for loading pinned casks") do |filename|
          options.export_filename = filename
          options.command = "load"
        end
      end
    end

    parser.parse!(args)

    if %w[pin unpin pinned livecheck run].include?(args[0])
      options.command = args[0] if options.export_filename == ""
      validate_command_args args, options
    end
    validate_options options

    options.casks = args

    self.options = options
  end

  def self.validate_command_args(args, options)
    odie "Missing CASK for #{options.command} command" if %w[pin unpin].include?(options.command) && args[1].nil?
  end

  def self.validate_options(options)
    # verbose and quiet cannot both exist
    odie "--quiet and --verbose cannot be specified at the same time" if options.quiet && options.verbose
  end
end
