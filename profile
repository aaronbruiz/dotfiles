# Only if using bash
if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# if running zsh, add to /etc/zsh/zprofile
# [ -f "$HOME/.profile" ] && source "$HOME/.profile"

# set zsh
# chsh -s $(which zsh) #change zsh with bash, sh

# --- THE HELPERS ---

# Helper: Add to PATH only if exists and not already there
add_to_path() {
    case ":$PATH:" in 
        *":$1:"*) ;; 
        *) [ -d "$1" ] && export PATH="$1:$PATH" ;; 
    esac
}

# Helper: Create a lazy loader for any tool
# Usage: lazy_load "tool_name" "init_command" "alias1" "alias2" ...
lazy_load() {
    local tool="$1"; local init="$2"; shift 2
    for cmd in "$tool" "$@"; do
        eval "$cmd() { unset -f $tool $@; $init; $cmd \"\$@\"; }"
    done
}

# --- PATH SETTINGS (Static) ---
#add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"
[ -s "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# If uv is used to manage python
if [ -d "$HOME/.rye/shorthands" ]; then
    add_to_path "$HOME/.rye/shorthands"
fi

# --- TOOLS SETTINGS (Static) ---
export LESSHISTFILE="$HOME/.cache/.lesshst"
export VIMINIT="source $HOME/.dotfiles/vim/vimrc"
export VIMCONFIG="$HOME/.config/vim"
export GPG_TTY=$(tty)

# Git config
[ -f "$HOME/.dotfiles/git/config" ] && export GIT_CONFIG_GLOBAL="$HOME/.dotfiles/git/config"

# --- TOOLS LOADING ---

# FNM Lazy Load
if [ -d "$HOME/.local/share/fnm" ]; then
    add_to_path "$HOME/.local/share/fnm"
    lazy_load "fnm" 'eval "$(fnm env)"' node npm npx
fi

# Go
if [ -d "/usr/local/go/bin" ] ; then
  export GOPATH="$HOME/.local/share/go"
  add_to_path "/usr/local/go/bin"
  add_to_path "$GOPATH/bin"
fi

# SSH Agent (Only starts when you use SSH)
lazy_load "ssh" 'eval "$(ssh-agent -s) > /dev/null"' ssh-add sftp scp

# uv (Python manager)
if command -v uv > /dev/null; then
    lazy_load "uv" 'eval "$(uv generate-shell-completion zsh)"' uvx
fi

