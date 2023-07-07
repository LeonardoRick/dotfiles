INSTALL_DIR="$(realpath $(dirname $0)/install)"
# Runs before everything to make this repo available inside ~/.dotfiles
$INSTALL_DIR/setup.sh

# Create symlinks of all files inside ./dist folder to ~/
$INSTALL_DIR/make_smlinks.sh

# Install apps
$INSTALL_DIR/apps/oh-my-zsh.sh