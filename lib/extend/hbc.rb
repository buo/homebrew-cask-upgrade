CASKROOM = Hbc.caskroom

module Hbc
  def self.outdated(options)
    outdated = []
    installed_count = Hbc.installed.length
    zero_pad = installed_count.to_s.length
    suppress_errors = !options.cask.nil? || false

    each_installed(suppress_errors) do |app, i|
      counter = "(%0#{zero_pad}d/%d)"
      string_template = "#{app[:full_name]} (#{app[:name]}): "

      if options.cask
        next unless options.cask[:name] == app[:name]
      else
        string_template = "#{counter} #{string_template}"
      end


      print format(string_template, i + 1, installed_count)
        puts "#{Tty.red}latest but forced to upgrade#{Tty.reset}"
      if options.all && app[:latest] == "latest"
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
          :full_name => cask.name.first,
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
