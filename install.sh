export TESTE_BATATA=123
INSTALL_DIR="$(realpath $(dirname $0)/install)"
# SETUP, runs before everything
$INSTALL_DIR/setup.sh

# create symlinks
$INSTALL_DIR/make_smlinks.sh

# INSTALL apps
$INSTALL_DIR/apps/oh-my-zsh.sh