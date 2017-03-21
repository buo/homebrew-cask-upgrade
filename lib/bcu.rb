$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "hbc"
require "extend/formatter"
require "extend/hbc"

module Bcu
  def self.process(args)
    parse!(args)

    outdated = find_outdated_apps
    return if outdated.empty?

    print_outdated_app(outdated)

    if options.dry_run
      printf "\nDo you want to upgrade %d app%s [y/N]? ", outdated.length, outdated.length > 1 ? "s" : ""
      input = STDIN.gets.strip

      if input.casecmp("y").zero?
        options.dry_run = false
      end
    end

    return if options.dry_run

    outdated.each do |app|
      ohai "Upgrading #{app[:token]} to #{app[:version]}"

      # Clean up the cask metadata container.
      system "rm -rf #{app[:cask].metadata_master_container_path}"

      # Force to install the latest version.
      system "brew cask install #{app[:token]} --force"

      # Remove the old versions.
      app[:current].each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app[:token]}/#{version}"
        end
      end
    end
  end

  def self.find_outdated_apps
    outdated = []

    ohai "Finding outdated apps"
    installed = Hbc.installed_apps

    if options.cask
      installed = installed.select { |app| app[:token] == options.cask }
      if installed.empty?
        onoe "#{Tty.red}Cask \"#{options.cask}\" is not installed.#{Tty.reset}"
        exit(1)
      end
    end

    table = [["No.", "Name", "Cask", "Current", "Latest", "State"]]
    installed.each_with_index do |app, i|
      row = []
      row << "#{i+1}/#{installed.length}"
      row << app[:name].to_s
      row << app[:token]
      row << app[:current].join(", ")
      row << app[:version]
      if options.all && app[:version] == "latest"
        row << "forced to upgrade"
        outdated.push app
      elsif app[:outdated?]
        row << "outdated"
        outdated.push app
      elsif app[:cask].nil?
        row << "no cask available"
      end
      table << row
    end
    puts Formatter.table(table)

    outdated
  end

  def self.print_outdated_app(outdated)
    table = [["No.", "Name", "Cask", "Current", "Latest", "State"]]
    outdated.each_with_index do |app, i|
      row = []
      row << "#{i+1}/#{outdated.length}"
      row << app[:name].to_s
      row << app[:token]
      row << app[:current].join(", ")
      row << app[:version]
      if options.all && app[:version] == "latest"
        row << "forced to upgrade"
      elsif app[:outdated?]
        row << "outdated"
      end
      table << row
    end

    puts
    ohai "Found outdated apps"
    puts Formatter.table(table)
  end
end
