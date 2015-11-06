BREW_HOME = `brew --repository`.strip
CASK_HOME = "#{BREW_HOME}/Library/Taps/caskroom/homebrew-cask"
$LOAD_PATH.unshift("#{CASK_HOME}/lib")

require 'vendor/homebrew-fork/global'
require 'hbc'

CASKROOM = "/opt/homebrew-cask/Caskroom"

def installed
  apps = []
  Hbc.installed.each do |name|
    cask = Hbc.load name.to_s
    apps << {
      :cask => cask,
      :name => name.to_s,
      :installed => installed_versions(name)
    }
  end
  apps
end

# Retrieves currently installed versions on the machine.
def installed_versions(name)
  Dir["#{CASKROOM}/#{name}/*"].map { |e| File.basename e }
end
