#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: scripts/tmux-setup.sh [--skip-tpm] [--skip-reload] [--dry-run]

Sets up tmux config from this repo by symlinking:
  ~/.tmux.conf -> <repo>/.config/tmux/.tmux.conf

Also installs TPM to ~/.tmux/plugins/tpm (unless --skip-tpm).
EOF
}

dry_run=0
skip_tpm=0
skip_reload=0

while [ "${1:-}" != "" ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) dry_run=1 ;;
    --skip-tpm) skip_tpm=1 ;;
    --skip-reload) skip_reload=1 ;;
    *) die "unknown arg: $1 (use --help)" ;;
  esac
  shift
done

run() {
  if [ "$dry_run" -eq 1 ]; then
    printf '+ %q' "$1"
    shift
    for arg in "$@"; do printf ' %q' "$arg"; done
    printf '\n'
    return 0
  fi
  "$@"
}

repo_root() {
  local script_dir root
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

  if command -v git >/dev/null 2>&1; then
    root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || true)"
    if [ -n "${root:-}" ]; then
      printf '%s\n' "$root"
      return 0
    fi
  fi

  (cd "$script_dir/.." && pwd -P)
}

ROOT="$(repo_root)"
SRC="$ROOT/.config/tmux/.tmux.conf"
DEST="${HOME:?}/.tmux.conf"

[ -f "$SRC" ] || die "missing tmux config: $SRC"

backup_existing_dest() {
  local ts backup
  ts="$(date +%Y%m%d%H%M%S)"
  backup="${DEST}.bak.${ts}"
  run mv "$DEST" "$backup"
  warn "moved existing $DEST to $backup"
}

link_tmux_conf() {
  if [ -L "$DEST" ]; then
    local current
    current="$(readlink "$DEST" || true)"
    if [ "$current" = "$SRC" ]; then
      log "ok: $DEST -> $SRC"
      return 0
    fi
    run rm "$DEST"
  elif [ -e "$DEST" ]; then
    backup_existing_dest
  fi

  run ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
}

install_tpm() {
  local plugins_dir tpm_dir
  plugins_dir="$HOME/.tmux/plugins"
  tpm_dir="$plugins_dir/tpm"

  run mkdir -p "$plugins_dir"

  if [ -x "$tpm_dir/tpm" ]; then
    log "ok: TPM already installed ($tpm_dir)"
    return 0
  fi

  if [ -e "$tpm_dir" ]; then
    warn "TPM dir exists but tpm is not executable: $tpm_dir"
    warn "Fix it manually or delete it and rerun."
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git not found; skipping TPM install"
    warn "Manual install: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    return 0
  fi

  run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
  log "installed: TPM ($tpm_dir)"
}

reload_tmux_if_running() {
  if [ "$skip_reload" -eq 1 ]; then
    return 0
  fi
  if ! command -v tmux >/dev/null 2>&1; then
    return 0
  fi
  if ! tmux ls >/dev/null 2>&1; then
    return 0
  fi

  if run tmux source-file "$DEST"; then
    log "reloaded: tmux source-file $DEST"
  else
    warn "failed to reload tmux config (you can run: tmux source-file $DEST)"
  fi
}

main() {
  link_tmux_conf
  if [ "$skip_tpm" -eq 0 ]; then
    install_tpm
  fi
  reload_tmux_if_running

  log "next: in tmux, press prefix + I to install plugins (TPM)."
}

main
