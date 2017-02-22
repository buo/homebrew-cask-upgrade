$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "hbc"
require "extend/hbc"
require "optparse"
require "ostruct"

module Bcu
  def self.parse(args)
    options = OpenStruct.new
    options.all = false
    options.cask = nil

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [CASK] [options]"

      opts.on("-a", "--all", "Force upgrade outdated apps including the ones marked as latest") do
        options.all = true
      end

      opts.on("--dry-run", "Print outdated apps without upgrading them") do
        options.dry_run = true
      end

      # `-h` is not available since the Homebrew hijacks it.
      opts.on_tail("--h", "Show this message") do
        puts opts
        exit
      end
    end

    parser.parse!(args)
    options
  end

  def self.process(args)
    options = parse(args)

    options.cask = get_cask(args[0]) unless args[0].nil?

    Hbc.outdated(options).each do |app|
      next if options.dry_run

      ohai "Upgrading #{app[:name]} to #{app[:latest]}"

      # Clean up the cask metadata container.
      system "rm -rf #{app[:cask].metadata_master_container_path}"

      # Force to install the latest version.
      system "brew cask install #{app[:name]} --force"

      # Remove the old versions.
      app[:installed].each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app[:name]}/#{version}"
        end
      end
    end
  end

  def self.get_cask(cask_name)
    cask = Hbc.get_installed_cask(cask_name)

    if cask.nil?
      onoe "#{Tty.red}Cask \"#{cask_name}\" is not installed.#{Tty.reset}"
      exit(1)
    end

    {
      cask: cask,
      name: cask.to_s,
      full_name: cask.name.first,
      latest: cask.version.to_s,
      installed: Hbc.installed_versions(cask.to_s),
    }
  end
end
