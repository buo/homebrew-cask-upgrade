# frozen_string_literal: true

require "bcu/module/pin"

module Bcu
  class Upgrade < Command
    include Utils::Output::Mixin

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
        cleanup(options, true)
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
        upgrade for_upgrade, options
      else
        upgrade outdated, options
      end

      cleanup(options, cleanup_necessary)
    end

    private

    def cleanup(options, cleanup_necessary)
      should_cleanup = options.cleanup && cleanup_necessary
      return unless should_cleanup

      ohai "Running cleanup"
      verbose_flag = options.verbose ? "--verbose" : ""
      cmd = "brew cleanup #{verbose_flag}"
      system cmd.to_s
    end

    def include_mas_applications(installed)
      result = IO.popen(%w[mas list]).read
      mac_apps = result.split("\n")

      region = IO.popen(%w[mas region]).read.strip.downcase

      mas_outdated = mas_load_outdated

      mac_apps.each do |app|
        data = parse_mas_app app
        next if data[:name].nil?

        new_version = mas_outdated[data[:name]]
        mas_cask = {
          cask:               nil,
          name:               data[:name],
          token:              data[:name],
          version_full:       new_version.nil? ? data[:installed_version] : new_version,
          version:            new_version.nil? ? data[:installed_version] : new_version,
          current_full:       data[:installed_version],
          current:            data[:installed_version],
          outdated?:          !new_version.nil?,
          auto_updates:       false,
          homepage:           "https://apps.apple.com/#{region}/app/id#{data[:id]}",
          installed_versions: [data[:installed_version]],
          mas:                true,
          mas_id:             data[:id],
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

        exit 0 if input.casecmp("q").zero?

        for_upgrade.push app if input.casecmp("y").zero?
      end
      for_upgrade
    end

    def upgrade(apps, options)
      return if apps.blank?

      if apps.length > 1
        ohai "Upgrading #{apps.length} apps"
        if options.verbose
          apps.each do |app|
            puts "#{app[:token]} #{app[:current]} -> #{app[:version]}"
          end
        end
      else
        ohai "Upgrading #{apps[0][:token]} to #{apps[0][:version]}"
      end

      installation_successful = install apps, options
      return unless installation_successful

      ohai "Cleaning up old versions" if options.verbose
      apps.each do |app|
        installation_cleanup app unless app[:mas]
      end
    end

    def install(apps, options)
      verbose_flag = options.verbose ? " --verbose" : ""

      # Split MAS and Homebrew apps
      mas_apps = apps.select { |app| app[:mas] }
      brew_apps = apps.reject { |app| app[:mas] }

      begin
        mas_cmd = nil
        unless mas_apps.empty?
          mas_ids = mas_apps.map { |app| app[:mas_id] }.join(" ")
          mas_cmd = "mas upgrade#{verbose_flag} #{mas_ids}"
        end

        brew_cmd = nil
        unless brew_apps.empty?
          # Force to install the latest version.
          brew_ids = brew_apps.map do |app|
            app[:tap].nil? ? app[:token] : "#{app[:tap]}/#{app[:token]}"
          end.join(" ")
          brew_cmd = "brew reinstall #{options.install_options} #{brew_ids} --force#{verbose_flag}"
        end

        success = true
        success &&= system brew_cmd.to_s if brew_cmd

        if mas_cmd && success
          ohai "Upgrading Mac App Store apps" if options.verbose
          success &&= system mas_cmd.to_s
        end
      rescue
        success = false
      end

      success
    end

    def installation_cleanup(app)
      # Remove the old versions.
      app[:installed_versions].each do |version|
        system "rm", "-rf", "#{CASKROOM}/#{app[:token]}/#{Shellwords.escape(version)}" if version != "latest"
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
        match = parse_mas_app app
        outdated[match[:name]] = match[:new_version] if match[:new_version]
      end
      outdated
    end

    def parse_mas_app(app)
      match = app.strip.split(/^(\d+)\s+(.+?)\s+\((.+)\)$/)
      version_upgrade = match[3].split(" -> ") 
      if version_upgrade.length == 2
        installed_version = version_upgrade[0]
        version = version_upgrade[1]
      else
        installed_version = match[3]
        version = nil
      end
      {
        id: match[1],
        name: match[2].downcase.strip, 
        installed_version: installed_version,
        new_version: version
      }
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
