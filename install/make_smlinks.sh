#! /usr/bin/env zsh

# source .exports because we need $DOTFILES to be defined
source ~/.dotfiles/dots/.exports

# Now let's symlinc all our dotfiles to the directory where they are expected (our home directory)
for FILE in $DOTFILES/dots/.*; do
  [ -f "$FILE" ] && ln -sfv $FILE ~
done

# link files inside folders
ln -sfv $DOTFILES/dots/.ssh/config ~/.ssh/config
rm -rf ~/.config/karabiner && ln -sfv $DOTFILES/dots/.config/karabiner ~/.config/karabiner