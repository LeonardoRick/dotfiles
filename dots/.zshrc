

##############################################################
# User configuration (keep at bottom)
##############################################################

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
# Path to your oh-my-zsh installation.
export ZSH=/Users/$USER/.oh-my-zsh


plugins=(
    git
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-completions
)
source $ZSH/oh-my-zsh.sh
source ~/.bash_profile
source ~/.zsh_functions


set_custom_zsh_theme_leonardorick
