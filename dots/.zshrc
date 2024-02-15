# Fig pre block. Keep at the top of this file.
[[ -f "$HOME/.fig/shell/zshrc.pre.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.pre.zsh"
plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)
source ~/.zsh_functions # need this before to have funciton defined
set_zsh_and_apply_leonardorick_theme


##############################################################
# User configuration (keep at bottom)
##############################################################
# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
source ~/.bash_profile

# allow the usage of direnv to manage environment variables and .envrc files
eval "$(direnv hook zsh)"

# Fig post block. Keep at the bottom of this file.
[[ -f "$HOME/.fig/shell/zshrc.post.zsh" ]] && builtin source "$HOME/.fig/shell/zshrc.post.zsh"


# Load Angular CLI autocompletion.
{ source <(ng completion script); } &>/dev/null
