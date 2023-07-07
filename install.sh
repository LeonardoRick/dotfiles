INSTALL_DIR="$(realpath $(dirname $0)/install)"

# Runs before everything to make this repo available inside ~/.dotfiles
$INSTALL_DIR/setup.sh

# Create symlinks of all files inside ./dist folder to ~/
$INSTALL_DIR/make_smlinks.sh

# Mac apps instalation
if [ $(uname) == "Darwin" ]; then
    $INSTALL_DIR/mac/apps/brew.sh
    $INSTALL_DIR/mac/apps/oh-my-zsh.sh
fi