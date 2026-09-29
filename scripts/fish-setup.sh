#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*"; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: scripts/fish-setup.sh [options]

このリポジトリの fish 設定を新しいマシンへ展開する。

  1. fish を Homebrew でインストール（未インストール時のみ）
  2. /etc/shells に登録し、ログインシェルを fish に変更
  3. 設定ファイルを ~/.config/fish/ へシンボリックリンク
       config.fish, fish_plugins, conf.d/*.fish
  4. fisher を導入し fish_plugins のプラグインをインストール
  5. theme/tide.fish のスナップショットを適用（プロンプト・配色の再現）

Options:
  --dry-run        実行せずコマンドだけ表示
  --skip-install   fish 自体のインストールを行わない
  --skip-shell     /etc/shells 登録とログインシェル変更を行わない
  --skip-plugins   fisher とプラグインのインストールを行わない
  --skip-theme     tide/配色スナップショットの適用を行わない
  -h, --help       このヘルプ
EOF
}

dry_run=0
skip_install=0
skip_shell=0
skip_plugins=0
skip_theme=0

while [ "${1:-}" != "" ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    --dry-run) dry_run=1 ;;
    --skip-install) skip_install=1 ;;
    --skip-shell) skip_shell=1 ;;
    --skip-plugins) skip_plugins=1 ;;
    --skip-theme) skip_theme=1 ;;
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
SRC_DIR="$ROOT/.config/fish"
DEST_DIR="${HOME:?}/.config/fish"

[ -d "$SRC_DIR" ] || die "missing fish config dir: $SRC_DIR"

# ---------------------------------------------------------------- fish install

install_fish() {
  if command -v fish >/dev/null 2>&1; then
    log "ok: fish already installed ($(command -v fish), $(fish --version 2>/dev/null))"
    return 0
  fi

  if ! command -v brew >/dev/null 2>&1; then
    warn "Homebrew が見つかりません。先に以下を実行してください:"
    warn '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    die "brew not found"
  fi

  run brew install fish
  log "installed: fish"
}

fish_path() {
  if command -v fish >/dev/null 2>&1; then
    command -v fish
    return 0
  fi
  # --dry-run で未インストールの場合は Homebrew の想定パスを返す
  if [ -d /opt/homebrew ]; then
    printf '%s\n' /opt/homebrew/bin/fish
  else
    printf '%s\n' /usr/local/bin/fish
  fi
}

# ---------------------------------------------------------------- login shell

set_login_shell() {
  local fish_bin
  fish_bin="$(fish_path)"

  if grep -qxF "$fish_bin" /etc/shells 2>/dev/null; then
    log "ok: $fish_bin already in /etc/shells"
  else
    log "adding $fish_bin to /etc/shells (sudo が必要です)"
    if [ "$dry_run" -eq 1 ]; then
      printf "+ sudo sh -c 'echo %q >> /etc/shells'\n" "$fish_bin"
    elif ! sudo sh -c "printf '%s\n' \"$fish_bin\" >> /etc/shells"; then
      warn "/etc/shells への追記に失敗しました。手動で追記してください。"
      return 0
    fi
  fi

  local current
  current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  if [ "$current" = "$fish_bin" ]; then
    log "ok: login shell is already $fish_bin"
    return 0
  fi

  if run chsh -s "$fish_bin"; then
    log "login shell changed to $fish_bin (次回ログイン以降で有効)"
  else
    warn "chsh に失敗しました。手動で実行してください: chsh -s $fish_bin"
  fi
}

# ---------------------------------------------------------------- symlinks

link_file() {
  local src="$1" dest="$2" current ts backup

  if [ -L "$dest" ]; then
    current="$(readlink "$dest" || true)"
    if [ "$current" = "$src" ]; then
      log "ok: $dest -> $src"
      return 0
    fi
    run rm "$dest"
  elif [ -e "$dest" ]; then
    ts="$(date +%Y%m%d%H%M%S)"
    backup="${dest}.bak.${ts}"
    run mv "$dest" "$backup"
    warn "moved existing $dest to $backup"
  fi

  run ln -s "$src" "$dest"
  log "linked: $dest -> $src"
}

link_config() {
  run mkdir -p "$DEST_DIR/conf.d"

  link_file "$SRC_DIR/config.fish" "$DEST_DIR/config.fish"
  link_file "$SRC_DIR/fish_plugins" "$DEST_DIR/fish_plugins"

  local f
  for f in "$SRC_DIR"/conf.d/*.fish; do
    [ -e "$f" ] || continue
    link_file "$f" "$DEST_DIR/conf.d/$(basename "$f")"
  done

  warn_unmanaged_conf_d
}

# リポジトリ管理外の conf.d ファイルを知らせる。
# tide が置く _tide_init.fish は fisher が管理するので対象外。
warn_unmanaged_conf_d() {
  local f name target
  for f in "$DEST_DIR"/conf.d/*.fish; do
    [ -e "$f" ] || continue
    name="$(basename "$f")"
    [ "$name" = "_tide_init.fish" ] && continue

    target="$(readlink "$f" 2>/dev/null || true)"
    case "$target" in
      "$SRC_DIR"/*) continue ;;
    esac

    warn "管理外の conf.d ファイルがあります: $f"
    warn "  リポジトリ側と内容が重複していないか確認し、不要なら削除してください"
  done
}

# ---------------------------------------------------------------- plugins

# fisher 本体を functions/fisher.fish として取得する。
# `fisher install jorgebucaran/fisher` は fish_plugins に追記してしまい
# リポジトリのファイルを書き換えるため、あえて自己登録はしない。
bootstrap_fisher() {
  local dest="$DEST_DIR/functions/fisher.fish"

  if [ -f "$dest" ]; then
    log "ok: fisher already installed"
    return 0
  fi

  run mkdir -p "$DEST_DIR/functions"
  if run curl -fsSL -o "$dest" \
    https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish; then
    log "installed: fisher"
  else
    warn "fisher の取得に失敗しました（ネットワークを確認してください）"
    return 1
  fi
}

# fisher は fish_prompt.fish のように複数プラグインが同名ファイルを持つ場合
# インストールを拒否する。競合ファイルを .backup.fish に退避して再試行する。
# （bobthefish と tide が両方 fish_prompt / fish_mode_prompt を持つため必要）
stash_conflicts() {
  local out="$1" f ts
  local found=0

  while IFS= read -r f; do
    [ -f "$f" ] || continue
    found=1
    local backup="${f%.fish}.backup.fish"
    if [ -e "$backup" ]; then
      ts="$(date +%Y%m%d%H%M%S)"
      backup="${f%.fish}.backup.${ts}.fish"
    fi
    run mv "$f" "$backup"
    warn "競合ファイルを退避: $(basename "$f") -> $(basename "$backup")"
  done <<EOF
$(printf '%s\n' "$out" | sed -n 's|^[[:space:]]\{1,\}\('"$DEST_DIR"'/.*\.fish\)$|\1|p')
EOF

  return $((1 - found))
}

fisher_install_one() {
  local spec="$1" fish_bin="$2" out

  if [ "$dry_run" -eq 1 ]; then
    printf '+ %q -c %q\n' "$fish_bin" "fisher install $spec"
    return 0
  fi

  if out="$("$fish_bin" -c "fisher install '$spec'" 2>&1 </dev/null)"; then
    log "installed: $spec"
    return 0
  fi

  if printf '%s\n' "$out" | grep -q 'conflicting files' && stash_conflicts "$out"; then
    if out="$("$fish_bin" -c "fisher install '$spec'" 2>&1 </dev/null)"; then
      log "installed: $spec (競合を退避して再試行)"
      return 0
    fi
  fi

  warn "インストールに失敗: $spec"
  printf '%s\n' "$out" | sed 's/^/    /' >&2
  return 1
}

install_plugins() {
  local fish_bin
  fish_bin="$(fish_path)"

  if [ "$dry_run" -eq 0 ] && [ ! -x "$fish_bin" ]; then
    warn "fish が無いためプラグイン導入をスキップします"
    return 0
  fi

  bootstrap_fisher || return 0

  # fisher は install のたびに fish_plugins を _fisher_plugins の内容で書き直す。
  # このファイルはリポジトリへのシンボリックリンクなので、導入に失敗した
  # プラグインがリポジトリ側から消えてしまう。先に一覧を読み込んでおく。
  local specs=()
  local spec
  while IFS= read -r spec || [ -n "$spec" ]; do
    case "$spec" in
      ''|'#'*) continue ;;
    esac
    specs+=("$spec")
  done < "$SRC_DIR/fish_plugins"

  [ "${#specs[@]}" -gt 0 ] || { warn "fish_plugins が空です"; return 0; }

  # 記載順にインストールする。順序は重要で、あとに来たプラグインが
  # 同名ファイルを上書きして有効になる（bobthefish より tide が後）。
  local failed=0
  for spec in "${specs[@]}"; do
    fisher_install_one "$spec" "$fish_bin" || failed=1
  done

  restore_fish_plugins "${specs[@]}"

  if [ "$failed" -eq 0 ]; then
    log "plugins installed from $SRC_DIR/fish_plugins"
  else
    warn "一部のプラグイン導入に失敗しました（fish 内で fisher update を試してください）"
  fi
}

# fisher が書き直した fish_plugins から抜け落ちた記載を戻す。
restore_fish_plugins() {
  local spec restored=0

  [ "$dry_run" -eq 1 ] && return 0
  [ -f "$SRC_DIR/fish_plugins" ] || return 0

  for spec in "$@"; do
    if ! grep -qxF "$spec" "$SRC_DIR/fish_plugins"; then
      printf '%s\n' "$spec" >> "$SRC_DIR/fish_plugins"
      restored=1
      warn "fish_plugins から消えていた記載を復元: $spec"
    fi
  done

  [ "$restored" -eq 1 ] && warn "  該当プラグインは未導入の可能性があります"
  return 0
}

# ---------------------------------------------------------------- theme

apply_theme() {
  local theme="$SRC_DIR/theme/tide.fish" fish_bin
  fish_bin="$(fish_path)"

  if [ ! -f "$theme" ]; then
    warn "テーマスナップショットがありません: $theme"
    warn "現行マシンで scripts/fish-export-theme.sh を実行して生成してください"
    return 0
  fi

  if [ "$dry_run" -eq 0 ] && [ ! -x "$fish_bin" ]; then
    warn "fish が無いためテーマ適用をスキップします"
    return 0
  fi

  if run "$fish_bin" -c "source $theme"; then
    log "applied: $theme (tide / 配色のユニバーサル変数)"
  else
    warn "テーマ適用に失敗しました（fish 内で source $theme を実行してください）"
  fi
}

# ---------------------------------------------------------------- main

main() {
  [ "$skip_install" -eq 1 ] || install_fish
  link_config
  [ "$skip_plugins" -eq 1 ] || install_plugins
  [ "$skip_theme" -eq 1 ] || apply_theme
  [ "$skip_shell" -eq 1 ] || set_login_shell

  log ""
  log "done. 新しいシェルを開くか 'exec fish' で反映してください。"
  log "プロンプトを調整したいときは fish 内で 'tide configure'、"
  log "その結果をリポジトリに残すときは 'bash scripts/fish-export-theme.sh' を実行します。"
}

main
