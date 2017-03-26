#!/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/bin/ruby -W0 -EUTF-8:UTF-8
# encoding: UTF-8

#:  * `cu` [`options`]
#:    Upgrade every outdated app installed by `brew cask`.
#:
#:  * `cu` cask [`options`]
#:    Upgrade a specific app.
#:
#:OPTIONS:
#:    If `--all` or `-a` is passed, include apps that auto-update in the
#:    upgrade.
#:
#:    If `--cleanup` is passed, clean up cached downloads and tracker symlinks
#:    after updating.
#:
#:    If `--force` or `-f` is passed, include apps that are marked as latest
#:    (i.e. force-reinstall them).
#:
#:    If `--yes` or `-y` is passed, update all outdated apps; answer yes to
#:    updating packages.

require "pathname"

$LOAD_PATH.unshift(File.expand_path("../../lib", Pathname.new(__FILE__).realpath))

require "bcu"

Bcu.process(ARGV)
