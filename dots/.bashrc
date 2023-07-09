#!/usr/bin/env bash

# (~/.logging takes precendence since all other alias depend on it)
source ~/.logging

source ~/.aliases
source ~/.exports
source ~/.functions
source ~/.zsh_exports # we need that to access brew on mac

setup_nvm
##############################################################
# User configuration (keep at bottom)
##############################################################
