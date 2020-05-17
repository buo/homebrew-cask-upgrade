#!/System/Library/Frameworks/Ruby.framework/Versions/2.0/usr/bin/ruby -W0 -EUTF-8:UTF-8

#:
#:`USAGE` brew cu [command=run] [CASK] [options]
#:
#:   `cu` [`options`]
#:      Upgrade every outdated app installed by `brew cask`.
#:
#:   `cu` CASK [`options`]
#:      Upgrade a specific app. You can use star
#:      to include more apps (`brew cu flash-**`)
#:      to upgrade all flash related casks
#:      (might require escaping `brew cu flash-\*`).
#:
#:   `cu pin` CASK
#:      Pin the current CASK version, preventing it from being
#:      upgraded when running the `brew cu` command. See also `unpin`.
#:
#:   `cu unpin` CASK
#:      Unpin specified CASK, allowing them to be
#:      upgraded by `brew cu` command. See also `pin`.
#:
#:   `cu pinned`
#:      Lists all CASKs that have been pinned.
#:
#:`OPTIONS`:
#:
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
#:    If `--verbose` or `-v` is passed, make output more verbose.
#:
#:    If `--no-quarantine` is passed, that option will be added to the install
#:    command (see `man brew-cask` for reference)
#:
#:`INTERACTIVE MODE`:
#:    After listing casks to upgrade you want those casks to be upgraded.
#:    By using the option `i` you will step into an interactive mode.
#:
#:    In the `interactive` mode you will be asked for every single app separately
#:        `y` will upgrade the app
#:        `p` will pin the app so it will not prompt you again, unless you unpin it
#:        `N` will skip the app upgrade
#:
#:    All unknown options will be considered as `N`
#:

require "pathname"

$LOAD_PATH.unshift(File.expand_path("../../lib", Pathname.new(__FILE__).realpath))

require "bcu"

Bcu.process(ARGV)
