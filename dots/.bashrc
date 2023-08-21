# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/bashrc.pre.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.pre.bash"
#!/usr/bin/env bash


# (~/.logging takes precendence since all other alias depend on it)
source ~/.logging

source ~/.aliases
source ~/.exports
source ~/.functions
source ~/.zsh_exports # we need that to access brew on mac

setup_nvm
setup_pyenv
##############################################################
# User configuration (keep at bottom)
##############################################################

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/bashrc.post.bash" ]] && builtin source "$HOME/.fig/shell/bashrc.post.bash"
