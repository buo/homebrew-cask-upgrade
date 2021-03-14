# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Upgrade < Command
    def process(_args, options)
      unless options.quiet
        ohai "Options"
        puts_stdout_or_stderr "Include auto-update (-a): #{Formatter.colorize(options.all,
                                                                              options.all ? "green" : "red")}"
        puts_stdout_or_stderr "Include latest (-f): #{Formatter.colorize(options.force,
                                                                         options.force ? "green" : "red")}"
      end

      unless options.no_brew_update
        ohai "Updating Homebrew"
        puts_stdout_or_stderr Cask.brew_update(options.verbose).stdout
      end

      installed = Cask.installed_apps

      ohai "Finding outdated apps"
      outdated, state_info = find_outdated_apps(installed, options)
      Formatter.print_app_table(installed, state_info, options) unless options.quiet
      if outdated.empty?
        puts_stdout_or_stderr "No outdated apps found." if options.quiet
        return
      end

      ohai "Found outdated apps"
      Formatter.print_app_table(outdated, state_info, options)
      printf "\n"

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

      outdated.each do |app|
        upgrade app, options, state_info
      end

      system "brew cleanup#{options.verbose ? " --verbose" : ""}" if options.cleanup && cleanup_necessary
    end

    private

    def upgrade(app, options, state_info)
      if options.interactive
        formatting = Formatter.formatting_for_app(state_info, app, options)
        printf 'Do you want to upgrade "%<app>s", [p]in it to exclude it from updates or [q]uit [y/p/q/N]? ',
               app: Formatter.colorize(app[:token], formatting[0])
        input = $stdin.gets.strip

        if input.casecmp("p").zero?
          cmd = Bcu::Pin::Add.new
          args = []
          args[1] = app[:token]
          cmd.process args, options
        end

        # rubocop:disable Rails/Exit
        exit 0 if input.casecmp("q").zero?
        # rubocop:enable Rails/Exit

        return unless input.casecmp("y").zero?
      end

      ohai "Upgrading #{app[:token]} to #{app[:version]}"
      installation_successful = install app, options

      installation_cleanup app, options if installation_successful
    end

    def install(app, options)
      verbose_flag = options.verbose ? "--verbose" : ""

      begin
        # Force to install the latest version.
        app_str = app[:tap].nil? ? app[:token] : "#{app[:tap]}/#{app[:token]}"
        cmd = "brew reinstall #{options.install_options} #{app_str} --force " + verbose_flag
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
        system "rm -rf #{CASKROOM}/#{app[:token]}/#{Shellwords.escape(version)}" unless version == "latest"
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
