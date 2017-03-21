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
      input = gets.strip

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

    installed.each do |app|
      output = ""
      if options.all && app[:version] == "latest"
        output << "#{Tty.red}#{app[:token]}#{Tty.reset}"
        output << " is marked as "
        output << "#{Tty.red}latest#{Tty.reset}"
        output << " but "
        output << "#{Tty.red}forced to upgrade#{Tty.reset}"
        outdated.push app
      elsif app[:outdated?]
        output << "#{Tty.red}#{app[:token]}#{Tty.reset}"
        output << " is installed with version "
        output << "#{Tty.red}#{app[:current].join(", ")}#{Tty.reset}"
        output << " and will be upgraded to "
        output << "#{Tty.green}#{app[:version]}#{Tty.reset}"
        outdated.push app
      else
        output << "#{Tty.green}#{app[:token]}#{Tty.reset}"
        output << " is installed with version "
        output << "#{Tty.green}#{app[:current].join(", ")}#{Tty.reset}"
        output << " and "
        output << "#{Tty.green}up to date#{Tty.reset}"
      end
      puts output
    end

    outdated
  end

  def self.print_outdated_app(outdated)
    padding = outdated.length.to_s.length

    table = [["No.", "App", "Token", "Current", "Latest"]]
    outdated.each_with_index do |app, i|
      row = []
      row << format("(%0#{padding}d/%d)", i + 1, outdated.length)
      row << app[:name]
      row << app[:token]
      row << app[:current].join(", ")
      row << app[:version]
      table << row
    end

    puts
    ohai "Found outdated apps"
    puts Formatter.table(table)
  end
end
