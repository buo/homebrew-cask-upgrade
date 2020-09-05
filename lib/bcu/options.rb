require "optparse"

module Bcu
  class << self
    attr_accessor :options
  end

  def self.parse!(args)
    options = build_config

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [CASK] [options]"

      opts.on("--ignore-config") do
        options = build_config false
      end

      opts.on("--debug") do
        options.debug = true
      end

      # Prevent using short -p syntax for pinning
      opts.on("-p") do
        onoe "invalid option -p, did you mean --pin?"
        exit 1
      end

      # Prevent using short -u syntax for unpinning
      opts.on("-u") do
        onoe "invalid option -u, did you mean --unpin?"
        exit 1
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
    end

    parser.parse!(args)

    if %w[pin unpin pinned run].include?(args[0])
      options.command = args[0]
      validate_command_args args, options
    end
    validate_options options

    options.casks = args

    self.options = options
  end

  def self.validate_command_args(args, options)
    if %w[pin unpin].include?(options.command) && args[1].nil?
      onoe "Missing CASK for #{options.command} command"
      exit 1
    end
  end

  def self.validate_options(options)
    # verbose and quiet cannot both exist
    if options.quiet && options.verbose
      onoe "--quiet and --verbose cannot be specified at the same time"
      exit 1
    end
  end

  def self.build_config(use_config_file = true)
    if use_config_file
      options = load_default_options
    else
      options = create_default_options
    end
    options.casks = nil
    options.install_options = ""
    options.list_pinned = false
    options.pin = nil
    options.unpin = nil
    options.command = "run"

    options
  end

  def self.load_default_options
    config_filename = "#{ENV["HOME"]}/.brew-cu"
    unless File.exist?(config_filename)
      odebug "Config file doesn't exist, creating"
      create_default_config_file config_filename
    end

    default_options = create_default_options
    if File.exist?(config_filename)
      odebug "Loading configuration from config file"
      handle = File.open(config_filename)
      options = YAML::load handle.read
      odebug "Configuration loaded", options
      OpenStruct.new(options.to_h)
    else
      # something went wrong while reading config file
      odebug "Config file wasn't created, setting default config"
      default_options
    end
  end

  def self.create_default_options
    default_values = default_config_hash
    default_options = OpenStruct.new
    default_options.all = default_values["all"]
    default_options.force = default_values["force"]
    default_options.cleanup = default_values["cleanup"]
    default_options.force_yes = default_values["force_yes"]
    default_options.no_brew_update = default_values["no_brew_update"]
    default_options.quiet = default_values["quiet"]
    default_options.verbose = default_values["verbose"]
    default_options.interactive = default_values["interactive"]
    default_options.debug = default_values["debug"]
    default_options
  end

  def self.create_default_config_file(config_filename)
    begin
      system "touch #{config_filename}"
      handle = File.open(config_filename, "w")
      handle.write default_config_hash.to_yaml
      handle.close
    rescue Exception => e
      odebug "RESCUE: File couldn't be created", e
      system "rm -f #{config_filename}"
    end
  end

  def self.default_config_hash
    {
        "all" => false,
        "force" => false,
        "cleanup" => false,
        "force_yes" => false,
        "no_brew_update" => false,
        "quiet" => false,
        "verbose" => false,
        "interactive" => false,
    }
  end
end
