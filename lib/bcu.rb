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
    options.dry_run = true

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [options]"

      opts.on("-a", "--all", "Force upgrade outdated apps including the ones marked as latest") do
        options.all = true
      end

      opts.on("-y", "--yes", "Update all outdated apps; answer yes to updating packages") do
        options.dry_run = false
      end

      opts.on("--cask [CASK]", "Specify a single cask for upgrade") do |cask_name|
        Hbc.each_installed(true) do |app|
          options.cask = app if cask_name == app[:name]
        end

        if options.cask.nil?
          onoe "#{Tty.red}Cask \"#{cask_name}\" is not installed.#{Tty.reset}"
          exit(1)
        end
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
    outdated = Hbc.outdated(options)
    
    return if outdated.length == 0
    
    if options.dry_run
      printf "\nDo you want to update %d package%s (y/n)? ", outdated.length, outdated.length > 1 ? 's' : ''
      to_update = gets
      to_update.chomp!
      
      if to_update.downcase == 'y'
        options.dry_run = false
      end
    end
    
    outdated.each do |app|
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
end
