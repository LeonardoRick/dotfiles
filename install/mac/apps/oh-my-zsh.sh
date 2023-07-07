#!/usr/bin/env bash
source ~/.bashrc

# Download oh-my-zsh framework
if [ ! -d ~/.oh-my-zsh ]; then
  log.info "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh) -s --unattended"
  log.success "Installed oh-my-zsh on $(zsh --version)!"
else
  log.warning "oh-my-zsh already installed!"
fi


# # Download plugins (DON'T FORGET, in case you want to add more, to add them to list of "plugins" on ~/.dotfiles/config/system/.zshrc!)
SYNTAX_HILIGHT_DIR=~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
AUTOSUGGESTIONS_DIR=~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
COMPLETIONS_DIR=~/.oh-my-zsh/custom/plugins/zsh-completions

if [ ! -d $SYNTAX_HILIGHT_DIR ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $SYNTAX_HILIGHT_DIR
fi

if [ ! -d $AUTOSUGGESTIONS_DIR ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions.git $AUTOSUGGESTIONS_DIR
fi

if [ ! -d $COMPLETIONS_DIR ]; then
  git clone https://github.com/zsh-users/zsh-completions.git $COMPLETIONS_DIR
fi

ln -sfv $DOTFILES/config/oh-my-zsh/themes/leonardorick.zsh-theme ~/.oh-my-zsh/themes/leonardorick.zsh-theme
# Print zsh version
log.success "Installed oh-my-zsh on $(zsh --version)!"