# based on default robbyrussel.zsh-theme
# PROMPT="%(?:%{$fg_bold[green]%}➜ :%{$fg_bold[red]%}➜ ) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT='%B%F{40}%n@%m%F{248}: %F{31}${(%):-%~}%f'
PROMPT+=' $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %b%F{248}$%f"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
