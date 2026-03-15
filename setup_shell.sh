#!/bin/bash

# Run script with sudo

# Update SO
apt update && apt upgrade -y
# Install packages
apt install btop unzip fzf tldr
# Install ZSH Plugins
source $HOME/.dotfiles/zsh/get-zsh-plugins.sh

# Setup configs
ln -sf $HOME/.dotfiles/aliasrc $HOME/.aliasrc
ln -sf $HOME/.dotfiles/zsh/zshrc $HOME/.zshrc
ln -sf $HOME/.dotfiles/profile $HOME/.profile

sed -i 's/^# skip_global_compinit=1$/skip_global_compinit=1/' /etc/zsh/zshrc
if ! grep -Fxq '[ -f "$HOME/.profile" ] && source "$HOME/.profile"' "/etc/zsh/zprofile"; then
	echo '[ -f "$HOME/.profile" ] && source "$HOME/.profile"' | sudo tee -a "/etc/zsh/zprofile"
fi

# Remove Ubuntu landscape and Snap for WSL, it takes 1.1s to init
apt purge landscape-client landscape-common snapd -y
apt autoremove --purge -y
rm -rf /snap /var/snap /var/lib/snapd /var/cache/snapd
apt update
