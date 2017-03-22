#!/bin/sh
#
#Create a noninteractive `brew-cask` external command by wrapping `brew-cu` (https://github.com/buo/homebrew-cask-upgrade)

#Use `brew-cu` to list all outdated casks, but reject upgrading them if `brew-cu` wants interactive input, by feeding it a stream of "n"
yes n | brew cu "${@}"

if [ "${#}" = "0" ]
then
	#If no arguments were passed to `brew-cu`, clear the last line of the terminal, which contains the prompt for user input
	tput cr && tput el
	
	#Print a message explaining how to upgrade outdated casks in place of the interactive prompt
	echo 'If there are outdated casks above, you can upgrade them by running `brew cask upgrade --yes`'
fi
