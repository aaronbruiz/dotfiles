#!/usr/bin/env bash
set -euo pipefail

PLUGINS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh"

mkdir -p "$PLUGINS_DIR"

log() {
  printf '%s\n' "$*"
}

install_or_update_sparse_repo() {
  local repo_url="$1"
  local repo_name="$2"
  shift 2
  local repo_dir="$PLUGINS_DIR/$repo_name"

  log "==> Installing/updating $repo_name"

  if [[ ! -d "$repo_dir/.git" ]]; then
    git clone --filter=blob:none --sparse "$repo_url" "$repo_dir"
  fi

  (
    cd "$repo_dir"
    git sparse-checkout init --no-cone 2>/dev/null || true
    git sparse-checkout set "$@"
    git pull --ff-only || true
  )
}

install_or_update_full_repo() {
  local repo_url="$1"
  local repo_name="$2"
  local repo_dir="$PLUGINS_DIR/$repo_name"

  log "==> Installing/updating $repo_name"

  if [[ ! -d "$repo_dir/.git" ]]; then
    git clone --depth=1 "$repo_url" "$repo_dir"
  else
    (
      cd "$repo_dir"
      git pull --ff-only
    )
  fi
}

main() {
  install_or_update_sparse_repo \
    "https://github.com/romkatv/zsh-defer.git" \
    "zsh-defer" \
    /zsh-defer.plugin.zsh

  install_or_update_sparse_repo \
    "https://github.com/olets/zsh-transient-prompt.git" \
    "zsh-transient-prompt" \
    /transient-prompt.plugin.zsh \
    /transient-prompt.zsh-theme

  install_or_update_sparse_repo \
    "https://github.com/zdharma-continuum/fast-syntax-highlighting.git" \
    "fast-syntax-highlighting" \
    /fast-syntax-highlighting.plugin.zsh \
    /fast-highlight \
    /fast-string-highlight \
    /fast-theme \
    /_fast-theme \
    /.fast-read-ini-file \
    /.fast-run-command \
    /.fast-run-git-command \
    /.fast-zts-read-all \
    /share \
    /themes \
    "/→chroma"

  install_or_update_sparse_repo \
    "https://github.com/zsh-users/zsh-history-substring-search.git" \
    "zsh-history-substring-search" \
    /zsh-history-substring-search.plugin.zsh \
    /zsh-history-substring-search.zsh

  install_or_update_sparse_repo \
    "https://github.com/zsh-users/zsh-autosuggestions.git" \
    "zsh-autosuggestions" \
    /zsh-autosuggestions.plugin.zsh \
    /zsh-autosuggestions.zsh

  log
  log "Done."
  log "Plugins directory: $PLUGINS_DIR"
  log
  log "Add these to your zsh config:"
  log "  source \"$PLUGINS_DIR/zsh-defer/zsh-defer.plugin.zsh\""
  log "  source \"$PLUGINS_DIR/zsh-autosuggestions/zsh-autosuggestions.plugin.zsh\""
  log "  source \"$PLUGINS_DIR/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh\""
  log "  source \"$PLUGINS_DIR/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh\""
  log "  source \"$PLUGINS_DIR/zsh-transient-prompt/transient-prompt.plugin.zsh\""
  log
  log "Suggested history-substring-search keybinds:"
  log "  bindkey '^[[A' history-substring-search-up"
  log "  bindkey '^[[B' history-substring-search-down"
}
main "$@"

