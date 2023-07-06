# link this current project folder to ~/.dotfiles
DOTFILES="$(realpath "$(dirname "$0")/..")"
rm -rf ~/.dotfiles
ln -s $DOTFILES ~/.dotfiles
