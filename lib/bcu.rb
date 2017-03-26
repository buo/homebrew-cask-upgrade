$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "hbc"
require "extend/formatter"
require "extend/hbc"

module Bcu
  def self.process(args)
    parse!(args)

    outdated, state_info = find_outdated_apps
    return if outdated.empty?

    puts
    ohai "Found outdated apps"
    print_app_table(outdated, state_info)

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

    Hbc::CLI::Cleanup.default.cleanup! if options.cleanup
  end

  def self.find_outdated_apps
    outdated = []
    state_info = Hash.new("")

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
      version_latest = (app[:version] == "latest")

      if options.force && options.all && version_latest && app[:auto_updates]
        outdated.push app
        state_info[app] = "forced to reinstall"
      elsif options.force && version_latest && !app[:auto_updates]
        outdated.push app
        state_info[app] = "forced to reinstall"
      elsif options.all && !version_latest && app[:auto_updates] && app[:outdated?]
        outdated.push app
        state_info[app] = "forced to upgrade"
      elsif !version_latest && !app[:auto_updates] && app[:outdated?]
        outdated.push app
        state_info[app] = "outdated"
      elsif version_latest || app[:outdated?]
        state_info[app] = "ignored"
      elsif app[:cask].nil?
        state_info[app] = "no cask available"
      end
    end

    print_app_table(installed, state_info)

    [outdated, state_info]
  end

  def self.print_app_table(apps, state_info)
    table = [["No.", "Name", "Cask", "Current", "Latest", "Auto-Update", "State"]]

    apps.each_with_index do |app, i|
      row = []
      row << "#{i+1}/#{apps.length}"
      row << app[:name].to_s
      row << app[:token]
      row << app[:current].join(", ")
      row << app[:version]
      row << (app[:auto_updates] ? "Y" : "")
      row << state_info[app]
      table << row
    end

    puts Formatter.table(table)
  end
end
