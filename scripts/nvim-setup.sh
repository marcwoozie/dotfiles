#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: scripts/nvim-setup.sh [options]

このリポジトリの Neovim (LazyVim) 設定を新しいマシンへ展開する。

  1. neovim を Homebrew でインストール（未インストール時のみ）
  2. LazyVim が利用する外部ツールをインストール
       ripgrep, fd, fzf, lazygit, tree-sitter-cli
  3. 設定ディレクトリをシンボリックリンク
       ~/.config/nvim -> <repo>/.config/nvim
  4. lazy-lock.json のバージョンでプラグインをインストール

Options:
  --dry-run        実行せずコマンドだけ表示
  --skip-install   neovim 自体のインストールを行わない
  --skip-deps      外部ツールのインストールを行わない
  --skip-plugins   プラグインのインストールを行わない
  -h, --help       このヘルプ
EOF
}

dry_run=0
skip_install=0
skip_deps=0
skip_plugins=0

while [ "${1:-}" != "" ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) dry_run=1 ;;
    --skip-install) skip_install=1 ;;
    --skip-deps) skip_deps=1 ;;
    --skip-plugins) skip_plugins=1 ;;
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
SRC="$ROOT/.config/nvim"
DEST="${HOME:?}/.config/nvim"

[ -d "$SRC" ] || die "missing nvim config dir: $SRC"

# ---------------------------------------------------------------- install

require_brew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi
  warn "Homebrew が見つかりません。先に以下を実行してください:"
  warn '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  die "brew not found"
}

install_nvim() {
  if command -v nvim >/dev/null 2>&1; then
    log "ok: neovim already installed ($(command -v nvim), $(nvim --version 2>/dev/null | head -n 1))"
    return 0
  fi

  require_brew
  run brew install neovim
  log "installed: neovim"
}

# LazyVim が利用する外部ツール。"<brew formula>:<コマンド名>" の形式で並べる。
#   ripgrep / fd / fzf  ファイル・文字列検索（picker）
#   lazygit             <leader>gg の Git UI
#   tree-sitter-cli     nvim-treesitter のパーサービルド
DEPS="ripgrep:rg fd:fd fzf:fzf lazygit:lazygit tree-sitter-cli:tree-sitter"

install_deps() {
  local pair formula cmd
  local missing=()

  for pair in $DEPS; do
    formula="${pair%%:*}"
    cmd="${pair##*:}"
    if command -v "$cmd" >/dev/null 2>&1; then
      log "ok: $formula already installed"
    else
      missing+=("$formula")
    fi
  done

  [ "${#missing[@]}" -gt 0 ] || return 0

  require_brew
  if run brew install "${missing[@]}"; then
    log "installed: ${missing[*]}"
  else
    warn "一部ツールのインストールに失敗しました: ${missing[*]}"
  fi
}

# ---------------------------------------------------------------- symlink

link_config() {
  local current ts backup

  if [ -L "$DEST" ]; then
    current="$(readlink "$DEST" || true)"
    if [ "$current" = "$SRC" ]; then
      log "ok: $DEST -> $SRC"
      return 0
    fi
    run rm "$DEST"
  elif [ -e "$DEST" ]; then
    ts="$(date +%Y%m%d%H%M%S)"
    backup="${DEST}.bak.${ts}"
    run mv "$DEST" "$backup"
    warn "moved existing $DEST to $backup"
  fi

  run mkdir -p "$(dirname "$DEST")"
  run ln -s "$SRC" "$DEST"
  log "linked: $DEST -> $SRC"
}

# ---------------------------------------------------------------- plugins

# 初回起動時に lazy.nvim 自体が clone され、不足プラグインが入る。
# そのうえで restore により lazy-lock.json のコミットへ揃える
# （sync / update と違い lazy-lock.json を書き換えない）。
install_plugins() {
  if [ "$dry_run" -eq 0 ] && ! command -v nvim >/dev/null 2>&1; then
    warn "nvim が無いためプラグイン導入をスキップします"
    return 0
  fi

  if ! command -v git >/dev/null 2>&1; then
    warn "git が無いためプラグイン導入をスキップします"
    return 0
  fi

  if run nvim --headless "+Lazy! restore" +qa; then
    log "plugins restored from $SRC/lazy-lock.json"
  else
    warn "プラグイン導入に失敗しました（nvim を起動して :Lazy restore を試してください）"
  fi
}

# ---------------------------------------------------------------- main

main() {
  [ "$skip_install" -eq 1 ] || install_nvim
  [ "$skip_deps" -eq 1 ] || install_deps
  link_config
  [ "$skip_plugins" -eq 1 ] || install_plugins

  log ""
  log "done. nvim を起動すると Mason が LSP / フォーマッタを、treesitter がパーサーを自動で導入します。"
  log "状態の確認は nvim 内で ':checkhealth' / ':Lazy' / ':Mason' を実行します。"
}

main
