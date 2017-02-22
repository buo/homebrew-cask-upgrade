# brew-cask-upgrade

`brew-cask-upgrade` is a command-line tool for upgrading every outdated app
installed by [Homebrew Cask](https://caskroom.github.io).

Homebrew Cask extends [Homebrew](http://brew.sh) and brings its elegance, simplicity, and speed to the installation and management of GUI macOS applications and large binaries alike, but it
lacks a sub-command like `brew upgrade` to upgrade installed apps, so if you want to upgrade the installed apps, you have to delete the previous versions and re-install the latest version manually for every single app.

With `brew-cask-upgrade`, you just need to type one command to upgrade all the apps installed by Homebrew Cask.

## Installation

```
brew tap buo/cask-upgrade
```

## Usage

Fetch the newest version of Homebrew Cask and all casks:

```
brew update
```

Upgrade outdated apps:

```
brew cu
```

Upgrade a specific app:

```
brew cu [CASK]
```

Options:

```
Usage: brew cu [options]
    -a, --all      Force upgrade outdated apps including the ones marked as latest
        --dry-run  Print outdated apps without upgrading them
        --h        Show this message
```

[![asciicast](https://asciinema.org/a/2xvi9l8rsps3troigke6b51qf.png)](https://asciinema.org/a/2xvi9l8rsps3troigke6b51qf)
