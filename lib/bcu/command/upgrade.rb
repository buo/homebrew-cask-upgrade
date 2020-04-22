require "bcu/module/pin"

module Bcu
  class Upgrade < Command
    def process(_args, options)
      unless options.quiet
        ohai "Options"
        puts "Include auto-update (-a): #{Formatter.colorize(options.all, options.all ? "green" : "red")}"
        puts "Include latest (-f): #{Formatter.colorize(options.force, options.force ? "green" : "red")}"
      end

      unless options.no_brew_update
        ohai "Updating Homebrew"
        puts Cask.brew_update(options.verbose).stdout
      end

      installed = Cask.installed_apps

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

      unless options.interactive || options.force_yes
        printf "Do you want to upgrade %<count>d app%<s>s or enter [i]nteractive mode [y/i/N]? ",
               count: outdated.length,
               s:     (outdated.length > 1) ? "s" : ""
        input = STDIN.gets.strip

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

      if options.cleanup && cleanup_necessary
        system "brew cleanup" + (options.verbose ? " --verbose" : "")
      end
    end

    private

    def upgrade(app, options, state_info)
      if options.interactive
        formatting = Formatter.formatting_for_app(state_info, app, options)
        printf 'Do you want to upgrade "%<app>s" or [p]in it to exclude it from updates [y/p/N]? ',
               app: Formatter.colorize(app[:token], formatting[0])
        input = STDIN.gets.strip

        Bcu::Pin::Add.process app[:token], options if input.casecmp("p").zero?

        return unless input.casecmp("y").zero?
      end

      ohai "Upgrading #{app[:token]} to #{app[:version]}"
      backup_metadata_folder = backup_metadata app, options
      installation_successful = install app, options

      if installation_successful
        installation_cleanup app, backup_metadata_folder
      elsif options.verbose || File.exist?(backup_metadata_folder)
        restore_metadata app, backup_metadata_folder
      end
    end

    def install(app, options)
      verbose_flag = options.verbose ? "--verbose" : ""

      begin
        # Force to install the latest version.
        success = system "brew cask install #{options.install_options} #{app[:token]} --force " + verbose_flag
      rescue
        success = false
      end

      success
    end

    def restore_metadata(app, backup_folder)
      # Put back the "old" metadata folder if error occurred.
      system "mv -f #{backup_folder} #{app[:cask].metadata_master_container_path}"
    end

    def installation_cleanup(app, backup_folder)
      # Remove the old versions.
      app[:current].each do |version|
        system "rm -rf #{CASKROOM}/#{app[:token]}/#{Shellwords.escape(version)}" unless version == "latest"
      end

      # Clean up the cask metadata backup container if everything went well.
      system "rm -rf #{backup_folder}"
    end

    def backup_metadata(app, options)
      backup_metadata_folder = app[:cask].metadata_master_container_path.to_s.gsub(%r{/.*\/$/}, "") + "-bck/"

      # Move the cask metadata container to backup folder
      if options.verbose || File.exist?(app[:cask].metadata_master_container_path)
        system "mv -f #{app[:cask].metadata_master_container_path} #{backup_metadata_folder}"
      end

      backup_metadata_folder
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

        if installed.empty?
          print_install_empty_message options.casks
          exit 1
        end
      end

      installed.each do |app|
        version_latest = (app[:version] == "latest")
        if Pin.pinned.include?(app[:token])
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

      [outdated, state_info]
    end

    def print_install_empty_message(cask_searched)
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
end
