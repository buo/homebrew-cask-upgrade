$LOAD_PATH.unshift("#{HOMEBREW_PREFIX}/Library/Homebrew/cask/lib")

require 'hbc'

CASKROOM = Hbc.caskroom

module Hbc
  def self.outdated
    outdated = []
    each_installed do |app, i|
      print "(#{i+1}/#{Hbc.installed.length}) #{app[:name]}: "
      if app[:installed].include? app[:latest]
        puts "up to date"
      else
        puts "#{app[:installed].join(', ')} -> #{app[:latest]}"
        outdated.push app
      end
    end
    outdated
  end

  def self.each_installed
    Hbc.installed.each_with_index do |name, i|
      cask = Hbc.load name.to_s
      yield({
        :name => name.to_s,
        :latest => cask.version.to_s,
        :installed => installed_versions(name)
      }, i)
    end
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(name)
    Dir["#{CASKROOM}/#{name}/*"].map { |e| File.basename e }
  end
end
