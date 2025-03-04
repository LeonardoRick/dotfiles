#!/usr/bin/env bash


# (~/.logging takes precendence since all other alias depend on it)
source ~/.logging

source ~/.aliases
source ~/.exports
source ~/.functions
# we need .zsh_exports imported here to access brew on mac from now (on setup_nvm for example)
source ~/.zsh_exports

# only run setup_nvm when spawning a non-root terminal
# since nvm is only set up locally
if [ "$EUID" -ne 0 ]; then
    setup_nvm
fi

setup_pyenv
##############################################################
# User configuration (keep at bottom)
##############################################################
