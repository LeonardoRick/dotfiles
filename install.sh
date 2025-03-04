INSTALL_DIR="$(realpath $(dirname $0)/install)"

# Make this repo available inside ~/.dotfiles and create symlinks of all files inside ./dist folder to ~/
$INSTALL_DIR/make_smlinks.sh

# # Mac apps instalation
if [ $(uname) == "Darwin" ]; then
    $DOTFILES/config/osx.sh
    $INSTALL_DIR/mac/apps/brew.sh
    $INSTALL_DIR/mac/apps/oh-my-zsh.sh
    $INSTALL_DIR/mac/mac.sh # run this after brew.sh
fi
