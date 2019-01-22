$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "bcu/options"
require "cask/all"
require "extend/formatter"
require "extend/cask"
require "fileutils"
require "set"

PINS_FILE = File.expand_path(File.dirname(__FILE__) + "/../pins")

module Bcu
  def self.process(args)
    parse!(args)

    FileUtils.touch(PINS_FILE)

    pins = Set[]
    File.open(PINS_FILE, "r") do |f|
      f.each_line do |app|
        pins.add(app.rstrip)
      end
    end

    if options.list_pins
      pins.each do |app|
        puts app
      end
      return
    end

    if options.pin
      if pins.include?(options.pin)
        puts "Already pinned: #{options.pin}"
      else
        File.open(PINS_FILE, "a") do |f|
          f.puts(options.pin)
        end
        puts "Pinned: #{options.pin}"
      end
      return
    end

    if options.unpin
      if pins.include?(options.unpin)
        pins.delete(options.unpin)
        File.open(PINS_FILE, "w") do |f|
          pins.each do |app|
            f.puts(app)
          end
        end
        puts "Unpinned: #{options.unpin}"
      else
        puts "Not pinned: #{options.unpin}"
      end
      return
    end

    unless options.quiet
      ohai "Options"
      puts "Include auto-update (-a): #{Formatter.colorize(options.all, options.all ? "green" : "red")}"
      puts "Include latest (-f): #{Formatter.colorize(options.force, options.force ? "green" : "red")}"
    end

    unless options.no_brew_update
      ohai "Updating Homebrew"
      puts Cask.brew_update.stdout
    end

    ohai "Finding outdated apps"
    outdated, state_info = find_outdated_apps(options.quiet, pins)
    if outdated.empty?
      puts "No outdated apps found." if options.quiet
      return
    end

    ohai "Found outdated apps"
    Formatter.print_app_table(outdated, state_info, options)

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
      system "brew cask install #{options.install_options} #{app[:token]} --force"

      # Remove the old versions.
      app[:current].each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app[:token]}/#{version}"
        end
      end
    end

    system "brew cleanup" if options.cleanup
  end

  def self.find_outdated_apps(quiet, pins)
    outdated = []
    state_info = Hash.new("")

    installed = Cask.installed_apps

    unless options.casks.empty?
      installed = installed.select do |app|
        found = false
        options.casks.each do |arg|
          found = true if app[:token] == arg || (arg.end_with?("*") && app[:token].start_with?(arg.slice(0..-2)))
        end
        found
      end

      if installed.empty?
        print_install_empty_message options.casks
        exit(1)
      end
    end

    installed.each do |app|
      version_latest = (app[:version] == "latest")
      if pins.include?(app[:token])
        state_info[app] = "pinned"
      elsif options.force && options.all && version_latest && app[:auto_updates]
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

    Formatter.print_app_table(installed, state_info, options) unless quiet

    [outdated, state_info]
  end

  def self.print_install_empty_message(cask_searched)
    if cask_searched.length == 1
      if cask_searched[0].end_with? "*"
        onoe "#{Tty.red}No Cask matching \"#{cask_searched[0]}\" is installed.#{Tty.reset}"
      else
        onoe "#{Tty.red}Cask \"#{cask_searched[0]}\" is not installed.#{Tty.reset}"
      end
    else
      onoe "#{Tty.red}No casks matching your arguments found.#{Tty.reset}"
    end
  end
end
