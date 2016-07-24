#!/bin/sh

BREW=`which brew`

"$BREW" cu

if [ $? -ne 0 ]; then
  BREW tap buo/cask-upgrade
  "$BREW" cu
fi
