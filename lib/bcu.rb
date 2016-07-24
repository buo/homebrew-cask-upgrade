require "extend/hbc"

module Bcu
  def self.process(args)
    Hbc.outdated.each do |app|
      puts "==> Upgrading #{app[:name]} to #{app[:latest]}"
      system "brew cask install #{app[:name]} --force"
      app[:installed].each do |version|
        system "rm -rf #{CASKROOM}/#{app[:name]}/#{version}"
      end
    end
  end
end
