$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "hbc"
require "extend/formatter"
require "extend/hbc"

module Bcu
  def self.process(args)
    parse!(args)

    ohai "Options"
    puts "Include auto-update (-a): #{Formatter.colorize(options.all, options.all ? "green" : "red")}"
    puts "Include latest (-f): #{Formatter.colorize(options.force, options.force ? "green" : "red")}"

    puts
    ohai "Finding outdated apps"
    outdated, state_info = find_outdated_apps
    return if outdated.empty?

    puts
    ohai "Found outdated apps"
    print_app_table(outdated, state_info)

    if options.dry_run
      printf "\nDo you want to upgrade %d app%s [y/N]? ", outdated.length, (outdated.length > 1) ? "s" : ""
      input = STDIN.gets.strip

      options.dry_run = false if input.casecmp("y").zero?
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

    Hbc::CLI::Cleanup.run if options.cleanup
  end

  def self.find_outdated_apps
    outdated = []
    state_info = Hash.new("")

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
    thead = []
    thead << Formatter::TableColumn.new(value: "")
    thead << Formatter::TableColumn.new(value: "Cask")
    thead << Formatter::TableColumn.new(value: "Current")
    thead << Formatter::TableColumn.new(value: "Latest")
    thead << Formatter::TableColumn.new(value: "A/U")
    thead << Formatter::TableColumn.new(value: "Result", align: "center")
    table = [thead]

    apps.each_with_index do |app, i|
      if state_info[app][0, 6] == "forced"
        color = "yellow"
        result = "[ FORCED ]"
      elsif app[:auto_updates]
        if options.all
          color = "green"
          result = "[   OK   ]"
        else
          color = "default"
          result = "[  PASS  ]"
        end
      elsif state_info[app] == "outdated"
        color = "red"
        result = "[OUTDATED]"
      else
        color = "green"
        result = "[   OK   ]"
      end

      row = []
      row << Formatter::TableColumn.new(value: "#{(i+1).to_s.rjust(apps.length.to_s.length)}/#{apps.length}")
      row << Formatter::TableColumn.new(value: app[:token], color: color)
      row << Formatter::TableColumn.new(value: app[:current].join(","))
      row << Formatter::TableColumn.new(value: app[:version], color: "magenta")
      row << Formatter::TableColumn.new(value: (app[:auto_updates]) ? " Y " : "", color: "magenta")
      row << Formatter::TableColumn.new(value: result, color: color)
      table << row
    end

    puts Formatter.table(table)
  end
end
