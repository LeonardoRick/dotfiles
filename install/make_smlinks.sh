#! /usr/bin/env zsh

# link this current project folder to ~/.dotfiles
DOTFILES="$(realpath "$(dirname "$0")/..")"
# rm -rf ~/.dotfiles && ln -s $DOTFILES ~/.dotfiles

# # source .exports because we need $DOTFILES to be defined
# source ~/.dotfiles/dots/.exports

# # Now let's symlinc all our dotfiles to the directory where they are expected (our home directory)
# for FILE in $DOTFILES/dots/.*; do
#   [ -f "$FILE" ] && ln -sfv $FILE ~
# done

# # link files inside folders
# ln -sfv $DOTFILES/dots/.ssh/config ~/.ssh/config
# rm -rf ~/.config/karabiner && ln -sfv $DOTFILES/dots/.config/karabiner ~/.config/karabiner

###################################################################################
####### link local setup to root setup terminal (requires root permissions) #######
###################################################################################
ln -sfv $HOME/.oh-my-zsh                      /var/root/.oh-my-zsh
ln -sfv $HOME/.aliases                        /var/root/.aliases
ln -sfv $HOME/.bash_profile                   /var/root/.bash_profile
ln -sfv $HOME/.bashrc                         /var/root/.bashrc
ln -sfv $HOME/.exports                        /var/root/.exports
ln -sfv $HOME/.functions                      /var/root/.functions
ln -sfv $HOME/.logging                        /var/root/.logging
ln -sfv $HOME/.zshrc                          /var/root/.zshrc
ln -sfv $HOME/.zsh_exports                    /var/root/.zsh_exports
ln -sfv $HOME/.zsh_functions                  /var/root/.zsh_functions
ln -sfv $HOME/completion-for-pnpm.zsh         /var/root/completion-for-pnpm.zsh

chmod -R a+rX ~/.oh-my-zsh # makes all subfolders world-readable/exec or group-readable/exec on .oh-my-zsh
sudo chsh -s "$(which zsh)" root # makes zsh the default terminal for the root
