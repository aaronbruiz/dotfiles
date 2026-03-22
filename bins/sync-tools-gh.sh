#!/bin/bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
TOOLS_FILE="$SCRIPT_DIR/tools.json"
STATE_FILE="$SCRIPT_DIR/.tools.state.json"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"

_ensure_files() {
  mkdir -p "$BIN_DIR"
  [ -f "$TOOLS_FILE" ] || { echo "Missing tools file: $TOOLS_FILE" >&2; return 1; }
  [ -f "$STATE_FILE" ] || { printf '{}\n' > "$STATE_FILE"; chmod 644 "$STATE_FILE"; }
}

_get_state_version() {
  local name="$1"
  jq -r --arg name "$name" '.[$name] // empty' "$STATE_FILE"
}

_set_state_version() {
  local name="$1" version="$2" tmp
  tmp="$(mktemp)" || return 1
  jq --arg name "$name" --arg version "$version" '.[$name] = $version' "$STATE_FILE" > "$tmp" &&
    mv "$tmp" "$STATE_FILE" &&   "$STATE_FILE"
}

_fail() {
  statuses["$1"]="failed"
  [ -d "$2" ] && rm -rf "$2"
}

_gh_install_latest() {
  local name="$1" repo="$2" pattern="$3"
  local tmp json latest_version saved_version url file bin out

  tmp="$(mktemp -d)" || _fail "$name" ""

  json="$(curl -fsSL --max-time 5 --connect-timeout 2 "https://api.github.com/repos/$repo/releases/latest")" || { _fail "$name" "$tmp"; return 1;}

#   echo "[DEBUG $name] API response length: $(printf '%s' "$json" | wc -c)" >&2
#   echo "[DEBUG $name] Assets: $(printf '%s' "$json" | jq -r '.assets[] | .name' | head -5)" >&2

  latest_version="$(printf '%s' "$json" | jq -r '.tag_name')"
  saved_version="$(_get_state_version "$name")"

  if [ -n "$saved_version" ] && [ "$saved_version" = "$latest_version" ]; then
    statuses["$name"]="unchanged"
    rm -rf "$tmp"
    return 0
  fi

  url="$(printf '%s' "$json" | jq -r --arg pat "$pattern" '.assets[] | select(.name | test($pat)) | .browser_download_url' | head -n1)" || { _fail "$name" "$tmp"; return 1;}

#   echo "[DEBUG $name] pattern: $pattern" >&2
#   echo "[DEBUG $name] url: $url" >&2

  [ -n "$url" ] && [ "$url" != "null" ] || { _fail "$name" "$tmp"; return 1; }

  file="$tmp/$(basename "$url")"
  curl -fL --max-time 30 --connect-timeout 5 "$url" -o "$file" || { _fail "$name" "$tmp"; return 1; }

  case "$file" in
    *.tar.gz|*.tgz) tar -xzf "$file" -C "$tmp" || { _fail "$name" "$tmp"; return 1; } ;;
    *.tbz|*.tar.bz2) tar -xjf "$file" -C "$tmp" || { _fail "$name" "$tmp"; return 1; } ;;
    *.tar.xz|*.txz) tar -xJf "$file" -C "$tmp" || { _fail "$name" "$tmp"; return 1; } ;;
    *.zip) unzip -q "$file" -d "$tmp" || { _fail "$name" "$tmp"; return 1; } ;;
  esac

  bin="$(find "$tmp" -type f -perm -u+x ! -name "$(basename "$file")" | head -n1)"
  out="$BIN_DIR/$name"

  if cp "${bin:-$file}" "$out" && chmod +x "$out" && _set_state_version "$name" "$latest_version"; then
    statuses["$name"]=$([ -n "$saved_version" ] && echo "updated" || echo "installed")
  else
    _fail "$name" "$tmp"
  fi

  rm -rf "$tmp"
}

_print_group() {
  local label="$1"
  shift
  [ "$#" -gt 0 ] || return 0
  printf '  %-10s %s\n' "$label:" "$*"
}

_print_summary() {
  local -a installed updated unchanged failed
  local name

  for name in "${!statuses[@]}"; do
    case "${statuses[$name]}" in
      installed) installed+=("$name") ;;
      updated)   updated+=("$name") ;;
      unchanged) unchanged+=("$name") ;;
      failed)    failed+=("$name") ;;
    esac
  done

  echo
  echo "Sync Tools Install summary:"
  _print_group "installed" "${installed[@]}"
  _print_group "updated" "${updated[@]}"
  _print_group "unchanged" "${unchanged[@]}"
  _print_group "failed" "${failed[@]}"
}

main() {
  case "$BIN_DIR" in
    /usr*|/opt*) [ "$EUID" -ne 0 ] && { echo "Installing to $BIN_DIR requires sudo..." >&2; exec sudo "$0" "$@"; };;
  esac

  _ensure_files || return 1

  declare -gA statuses
  local name repo pattern

  while IFS=$'\t' read -r name repo pattern; do
    _gh_install_latest "$name" "$repo" "$pattern"
  done < <(
    jq -r '.[] | [.name, .repo, .pattern] | @tsv' "$TOOLS_FILE"
  )

  _print_summary
}

main "$@"
unset -f _ensure_files _get_state_version _set_state_version _fail _gh_install_latest _print_group _print_summary
unset statuses
