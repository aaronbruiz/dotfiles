# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

#-- Personal changes

# if running zsh, add to /etc/zsh/zprofile
# [ -f "$HOME/.profile" ] && source "$HOME/.profile"

# Local bin
. "$HOME/.local/bin/env"

export LESSHISTFILE="$HOME/.cache/.lesshst"

# vim
export VIMINIT="source $HOME/.dotfiles/vim/vimrc"
export VIMCONFIG="$HOME/.config/vim"

# set zsh
# chsh -s $(which zsh) #change zsh with bash, sh

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
  unset FNM_PATH  
fi

# terraform in /usr/bin
export TF_CLI_CONFIG_FILE="$HOME/.dotfiles/terraform/terraform.rc"

# Go
if [ -d "/usr/local/go/bin" ] ; then
  export GOPATH="$HOME/.local/share/go"
  export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"
fi

# gpg key
export GPG_TTY=$(tty)

# git config
GIT_PATH="$HOME/.dotfiles/git/config"
if [ -f "$GIT_PATH" ] ; then
    export GIT_CONFIG_GLOBAL="$GIT_PATH"
    unset GIT_PATH
fi
