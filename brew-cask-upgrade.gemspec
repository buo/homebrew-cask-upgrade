# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "brew-cask-upgrade"
  s.version     = "2.0.2"
  s.summary     = "A command line tool for Homebrew Cask"
  s.description = "A command line tool for upgrading every outdated app installed by Homebrew Cask"
  s.authors     = ["buo"]
  s.email       = "buo@users.noreply.github.com"
  s.files       = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  s.homepage    = "https://github.com/buo/homebrew-cask-upgrade"
  s.license     = "MIT"

  s.bindir      = "bin"
  s.executables = %w[brew-cask-upgrade]
  s.required_ruby_version = "> 3.3.0"
  s.metadata = {
    "rubygems_mfa_required" => "true",
  }
end
