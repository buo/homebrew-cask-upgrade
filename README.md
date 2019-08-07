[![status](https://travis-ci.org/buo/homebrew-cask-upgrade.svg?branch=master)](https://travis-ci.org/buo/homebrew-cask-upgrade)

# brew-cask-upgrade

`brew-cask-upgrade` is a command-line tool for upgrading every outdated app
installed by [Homebrew Cask](https://caskroom.github.io).

Homebrew Cask extends [Homebrew](http://brew.sh) and brings its elegance, simplicity, and speed to the installation and management of GUI macOS applications and large binaries alike.

`brew-cask-upgrade` is an external command to replace the native `upgrade` by offering interactivity, an improved interface, and higher granularity of what to upgrade.

## Installation

```
brew tap buo/cask-upgrade
```

## Usage

Upgrade outdated apps:

```
brew cu
```

Upgrade a specific app:

```
brew cu [CASK]
```

While running the `brew cu` command without any other further options, the script automatically runs `brew update` to get
latest versions of all the installed casks (this can be disabled, see options below).

It is also possible to use `*` to instal multiple casks at once, i.e. `brew cu flash-*` to install all casks starting with `flash-` prefix.

[![asciicast](https://asciinema.org/a/DlXUmiFFVnDhIDe2tCGo3ecLW.png)](https://asciinema.org/a/DlXUmiFFVnDhIDe2tCGo3ecLW)

### Apps with auto-update

If the app has the auto update functionality (they ask you themselves, if you want to upgrade them), they are not
upgraded while running `brew cu`. If you want to upgrade them, pass `--all` option to include also those kind of apps.

Please note, that if you update the apps using their auto-update functionality, that change will not reflect in the
`brew cu` script! Tracked version gets only updated, when the app is upgraded through `brew cu --all`.

### Options

```
Usage: brew cu [CASK] [options]
    -a, --all             Include apps that auto-update in the upgrade.
        --cleanup         Cleans up cached downloads and tracker symlinks after
                          updating.
    -f  --force           Include apps that are marked as latest
                          (i.e. force-reinstall them).
        --no-brew-update  Prevent auto-update of Homebrew, taps, and formulae
                          before checking outdated apps.
    -y, --yes             Update all outdated apps; answer yes to updating packages.
    -q, --quiet           Do not show information about installed apps or current options.
        --no-quarantine   Pass --no-quarantine option to `brew cask install`.
        --pinned          Print all pinned apps. See also `pin`.
        --pin CASK        Pin the current app version, preventing it from being 
                          upgraded when issuing the `brew cu` command. See also `unpin`.
        --unpin CASK      Unpin the current app version, allowing them to be 
                          upgraded by `brew cu` command. See also `pin`.
    -i, --interactive     Running update in interactive mode    
```

Display usage instructions:
```sh
brew help cu
```

### Interactive mode

When using interactive mode (by adding `--interactive` argument or confirming app installation with `i`) will trigger per-cask confirmation.
For every cask it is then possible to use following options:
- `y` will install the current cask update
- `N` will skip the installation of current cask
- `p` will pin the current version of the cask (see [version pinning](#version-pinning))

### Version pinning

Pinned apps will not be updated by `brew cu` until they are unpinned.
NB: version pinning in `brew cu` will not prevent `brew cask upgrade` from updating pinned apps.
