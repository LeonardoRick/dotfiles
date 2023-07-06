# link this folder to .dotfiles
DOTFILES="$(realpath "$(dirname "$0")/..")"
rm -rf ~/.dotfiles
ln -s $DOTFILES ~/.dotfiles
# source exports so DOTS_DIRECTORY is available
source ~/.dotfiles/dots/.exports
# Now let's symlinc all our dotfiles to the directory where they are expected (our home directory)

for FILE in $DOTS_DIRECTORY/dots/.*; do
  [ -f "$FILE" ] && ln -sfv $FILE ~
done