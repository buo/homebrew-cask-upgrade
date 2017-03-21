CASKROOM = Hbc.caskroom

module Hbc
  def self.installed_apps
    Hbc.installed.map do |cask|
      installed = installed_versions(cask.token)
      {
        :cask => cask,
        :name => cask.name.first,
        :token => cask.token,
        :version => cask.version.to_s,
        :current => installed,
        :outdated? => cask.instance_of?(Cask) && !installed.include?(cask.version.to_s),
        :withoutSource? => cask.instance_of?(WithoutSource),
      }
    end
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(token)
    Dir["#{CASKROOM}/#{token}/*"].map { |e| File.basename e }
  end
end
