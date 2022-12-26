# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Upgrade < Command
    def process(_args, options)
      return run_process(options) if $stdout.tty?

      redirect_stdout($stderr) do
        run_process(options)
      end
    end

    def run_process(options)
      unless options.quiet
        ohai "Options"
        auto_update_message = Formatter.colorize(options.all, options.all ? "green" : "red")
        puts "Include auto-update (-a): #{auto_update_message}"
        latest_message = Formatter.colorize(options.force, options.force ? "green" : "red")
        puts "Include latest (-f): #{latest_message}"
        include_mas_message = Formatter.colorize(options.include_mas, options.include_mas ? "green" : "red")
        puts "Include mac app store (--include-mas): #{include_mas_message}" if options.include_mas
      end

      unless options.no_brew_update
        ohai "Updating Homebrew"
        puts Cask.brew_update(options.verbose).stdout
      end

      installed = Cask.installed_apps(options)
      include_mas_applications installed if options.include_mas

      ohai "Finding outdated apps"
      outdated, state_info = find_outdated_apps(installed, options)
      Formatter.print_app_table(installed, state_info, options) unless options.quiet
      if outdated.empty?
        puts "No outdated apps found." if options.quiet
        return
      end

      ohai "Found outdated apps"
      Formatter.print_app_table(outdated, state_info, options)
      printf "\n"

      exit(outdated.length) if options.report_only

      if !options.interactive && !options.force_yes
        printf "Do you want to upgrade %<count>d app%<s>s or enter [i]nteractive mode [y/i/N]? ",
               count: outdated.length,
               s:     (outdated.length > 1) ? "s" : ""
        input = $stdin.gets.strip

        if input.casecmp("i").zero?
          options.interactive = true
        else
          return unless input.casecmp("y").zero?
        end
      end

      # In interactive flow we're not sure if we need to clean up
      cleanup_necessary = !options.interactive

      if options.interactive
        for_upgrade = to_upgrade_interactively outdated, options, state_info
        for_upgrade.each do |app|
          upgrade app, options
        end
      else
        outdated.each do |app|
          upgrade app, options
        end
      end

      system "brew", "cleanup", options.verbose ? "--verbose": "" if options.cleanup && cleanup_necessary
    end

    private

    def include_mas_applications(installed)
      result = IO.popen(%w[mas list]).read
      mac_apps = result.split("\n")

      mas_outdated = mas_load_outdated

      mac_apps.each do |app|
        data = app.split(/^(\d+)\s+(.+)\s+\((.+)\)$/)
        token = data[2].downcase.strip
        new_version = mas_outdated[token]
        mas_cask = {
          cask:         nil,
          name:         data[2],
          token:        token,
          version:      new_version.nil? ? data[3] : new_version,
          current:      data[3],
          outdated?:    !new_version.nil?,
          auto_updates: false,
          mas:          true,
          mas_id:       data[1].strip,
        }
        installed.push(mas_cask)
      end

      installed.sort_by! { |cask| cask[:token] }
    end

    def to_upgrade_interactively(outdated, options, state_info)
      for_upgrade = []
      outdated.each do |app|
        formatting = Formatter.formatting_for_app(state_info, app, options)
        printf 'Do you want to upgrade "%<app>s", [p]in it to exclude it from updates or [q]uit [y/p/q/N]? ',
               app: Formatter.colorize(app[:token], formatting[0])
        input = $stdin.gets.strip

        if input.casecmp("p").zero?
          if app[:mas]
            onoe "Pinning is not yet supported for MAS applications."
          else
            cmd = Bcu::Pin::Add.new
            args = []
            args[1] = app[:token]
            cmd.process args, options
          end
        end

        # rubocop:disable Rails/Exit
        exit 0 if input.casecmp("q").zero?
        # rubocop:enable Rails/Exit

        for_upgrade.push app if input.casecmp("y").zero?
      end
      for_upgrade
    end

    def upgrade(app, options)
      ohai "Upgrading #{app[:token]} to #{app[:version]}"
      installation_successful = install app, options

      installation_cleanup app, options if installation_successful && !app[:mas]
    end

    def install(app, options)
      verbose_flag = options.verbose ? "--verbose" : ""

      begin
        if app[:mas]
          cmd = "mas upgrade #{app[:mas_id]}"
        else
          # Force to install the latest version.
          app_str = app[:tap].nil? ? app[:token] : "#{app[:tap]}/#{app[:token]}"
          cmd = "brew reinstall #{options.install_options} #{app_str} --force " + verbose_flag
        end
        success = system cmd.to_s
      rescue
        success = false
      end

      success
    end

    def installation_cleanup(app, options)
      ohai "Cleaning up old versions" if options.verbose
      # Remove the old versions.
      app[:installed_versions].each do |version|
        system "rm", "-rf", "#{CASKROOM}/#{app[:token]}/#{Shellwords.escape(version)}" unless version == "latest"
      end
    end

    def find_outdated_apps(installed, options)
      outdated = []
      state_info = Hash.new("")

      unless options.casks.empty?
        installed = installed.select do |app|
          found = false
          options.casks.each do |arg|
            found = true if app[:token] == arg || (arg.end_with?("*") && app[:token].start_with?(arg.slice(0..-2)))
          end
          found
        end

        odie(install_empty_message(options.casks)) if installed.empty?
      end

      installed.each do |app|
        version_latest = (app[:version] == "latest")
        if Pin.pinned.include?(app[:token])
          state_info[app] = "pinned"
        elsif (options.force && version_latest && app[:auto_updates] && options.all) ||
              (options.force && version_latest && !app[:auto_updates])
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

      [outdated, state_info]
    end

    def mas_load_outdated
      result = IO.popen(%w[mas outdated]).read
      mac_apps = result.split("\n")
      outdated = {}
      mac_apps.each do |app|
        data = app.split(/^(\d+)\s+(.+)\s+\((.+) -> (.+)\)$/)
        outdated[data[2].downcase.strip] = data[4]
      end
      outdated
    end

    def install_empty_message(cask_searched)
      if cask_searched.length == 1
        if cask_searched[0].end_with? "*"
          "#{Tty.red}No Cask matching \"#{cask_searched[0]}\" is installed.#{Tty.reset}"
        else
          "#{Tty.red}Cask \"#{cask_searched[0]}\" is not installed.#{Tty.reset}"
        end
      else
        "#{Tty.red}No casks matching your arguments found.#{Tty.reset}"
      end
    end
  end
end
