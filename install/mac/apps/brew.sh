#!/usr/bin/env zsh
source ~/.bashrc

MAC_DIR=$DOTS_DIRECTORY/install/mac
if test ! $(which brew); then;
    log.info 'Installing Homebrew...'
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

    cat << EOT >> ~/.zsh_exports
    # Brew Configuration
    $(/opt/homebrew/bin/brew shellenv)
EOT

    log.info "1️⃣  ⚙️  Installing all Brewfile apps"
    brew bundle install --no-upgrade --verbose --file=$MAC_DIR/Brewfile

    log.info "2️⃣  ⚙️  Installing all Caskfile (UI) apps"
    brew bundle install --no-upgrade --verbose --file=$MAC_DIR/Caskfile

    log.info "3️⃣  ⚙️  Installing all Masfile (App Store) apps"
    brew bundle install --no-upgrade --verbose --file=$MAC_DIR/Masfile
else
    log.warning 'Homebrew already installed! Skipping brew installation and all apps installation'
fi

