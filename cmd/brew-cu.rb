#!/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/bin/ruby -W0 -EUTF-8:UTF-8

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
#:    If `--no-brew-update` is passed, prevent auto-update of Homebrew, taps,
#:    and formulae before checking outdated apps.
#:
#:    If `--yes` or `-y` is passed, update all outdated apps; answer yes to
#:    updating packages.
#:
#:    If `--quiet` or `-q` is passed, do not show information about installed
#:    apps or current options.
#:
#:    If `--no-quarantine` is passed, that option will be added to the install
#:    command (see `man brew-cask` for reference)

require "pathname"

$LOAD_PATH.unshift(File.expand_path("../../lib", Pathname.new(__FILE__).realpath))

require "bcu"

Bcu.process(ARGV)
