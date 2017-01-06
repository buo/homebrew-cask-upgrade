$LOAD_PATH.unshift("#{HOMEBREW_REPOSITORY}/Library/Homebrew/cask/lib")

require "hbc"

CASKROOM = Hbc.caskroom

module Hbc
  def self.outdated(including_latest = false)
    outdated = []
    installed_count = Hbc.installed.length
    zero_pad = installed_count.to_s.length
    each_installed do |app, i|
      string_template = "(%0#{zero_pad}d/%d) #{app[:name]}: "
      print format(string_template, i + 1, installed_count)
      if including_latest && app[:latest] == "latest"
        puts "#{Tty.red}latest but forced to upgrade#{Tty.reset}"
        outdated.push app
      elsif app[:installed].include? app[:latest]
        puts "#{Tty.green}up to date#{Tty.reset}"
      else
        puts "#{Tty.red}#{app[:installed].join(", ")}#{Tty.reset} -> #{Tty.green}#{app[:latest]}#{Tty.reset}"
        outdated.push app
      end
    end
    outdated
  end

  def self.each_installed(suppress_errors = false)
    Hbc.installed.each_with_index do |name, i|
      begin
        cask = Hbc.load name.to_s
        yield({
          :cask => cask,
          :name => name.to_s,
          :latest => cask.version.to_s,
          :installed => installed_versions(name),
        }, i)
      rescue Hbc::CaskError => e
        puts e unless suppress_errors
      end
    end
  end

  # Retrieves currently installed versions on the machine.
  def self.installed_versions(name)
    Dir["#{CASKROOM}/#{name}/*"].map { |e| File.basename e }
  end
end
