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


# Load Angular CLI autocompletion.
{ source <(ng completion script); } &>/dev/null

# pnpm
export PNPM_HOME="/Users/leonardorick/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
source ~/completion-for-pnpm.zsh
# pnpm end
