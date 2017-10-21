CASKROOM = Hbc.caskroom

module Hbc
  def self.installed_apps
    # Manually retrieve installed apps instead of using Hbc.installed because
    # it raises errors while iterating and stops.
    installed = Dir["#{CASKROOM}/*"].map { |e| File.basename e }

    installed = installed.map do |token|
      versions = installed_versions(token)
      begin
        cask = load_cask(token)
        {
          :cask => cask,
          :name => cask.name.first,
          :token => cask.token,
          :version => cask.version.to_s,
          :current => versions,
          :outdated? => cask.instance_of?(Cask) && !versions.include?(cask.version.to_s),
          :auto_updates => cask.auto_updates,
        }
      rescue Hbc::CaskUnavailableError
        {
          :cask => nil,
          :name => nil,
          :token => token,
          :version => nil,
          :current => versions,
          :outdated? => false,
          :auto_updates => false,
        }
      end
    end

    installed.sort_by { |a| a[:token] }
  end

  # See: https://github.com/buo/homebrew-cask-upgrade/issues/43
  def self.load_cask(token)
    begin
      cask = CaskLoader.load(token)
    rescue NoMethodError
      cask = Hbc.load(token)
    end
    cask
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(token)
    Dir["#{CASKROOM}/#{token}/*"].map { |e| File.basename e }
  end

  def self.brew_update
    Hbc::SystemCommand.run(HOMEBREW_BREW_FILE, args: ["update"], print_stderr: true, print_stdout: false)
  end
end
