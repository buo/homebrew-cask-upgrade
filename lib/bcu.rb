require "extend/hbc"
require "optparse"
require "ostruct"

module Bcu
  def self.parse(args)
    options = OpenStruct.new
    options.all = false

    parser = OptionParser.new do |opts|
      opts.banner = "Usage: brew cu [options]"

      opts.on("-a", "--all", "Force upgrade outdated apps including the ones marked as latest") do
        options.all = true
      end
    end

    parser.parse!(args)
    options
  end

  def self.process(args)
    options = parse(args)
    Hbc.outdated(options.all).each do |app|
      puts "==> Upgrading #{app[:name]} to #{app[:latest]}"
      system "brew cask install #{app[:name]} --force"
      app[:installed].each do |version|
        unless version == "latest"
          system "rm -rf #{CASKROOM}/#{app[:name]}/#{version}"
        end
      end
    end
  end
end
