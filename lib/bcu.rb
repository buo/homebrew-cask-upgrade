require "extend/hbc"
require "optparse"
require "ostruct"

module Bcu
  def self.parse(args)
    options = OpenStruct.new
    options.all = false

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [options]"

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
    begin
      Hbc::CLI::Update.run
    rescue SystemExit
      $stdout
    end
    Hbc.outdated(options.all).each do |app|
      next if options.dry_run

      puts "==> Upgrading #{app[:name]} to #{app[:latest]}"

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
end
