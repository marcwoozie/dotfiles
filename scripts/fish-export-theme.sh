#!/usr/bin/env bash
# 現在の fish のユニバーサル変数（tide のプロンプト設定と配色）を
# .config/fish/theme/tide.fish にスナップショットとして書き出す。
# 新しいマシンでは scripts/fish-setup.sh がこのファイルを読み込んで見た目を再現する。
set -euo pipefail

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

command -v fish >/dev/null 2>&1 || die "fish が見つかりません"

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null || (cd "$script_dir/.." && pwd -P))"
DEST="$ROOT/.config/fish/theme/tide.fish"

mkdir -p "$(dirname "$DEST")"

# キャッシュ・fisher の内部状態（_ 始まり）とマシン固有の PATH は除外する
FISH_SNIPPET='
for name in (set --names --universal)
    switch $name
        case "_*" fish_user_paths __fish_initialized
            # 除外
        case "tide_*" "fish_color_*" "fish_pager_color_*" fish_key_bindings VIRTUAL_ENV_DISABLE_PROMPT
            echo "set -U $name" (string escape -- $$name)
    end
end'

{
  printf '# 自動生成: scripts/fish-export-theme.sh\n'
  printf '# 直接編集せず、fish 側で tide configure 等を実行してから再生成すること。\n\n'
  fish -c "$FISH_SNIPPET" 2>/dev/null | LC_ALL=C sort
} > "$DEST"

count="$(grep -c '^set -U ' "$DEST" || true)"
[ "$count" -gt 0 ] || die "変数を取得できませんでした: $DEST"
printf 'exported: %s (%s 変数)\n' "$DEST" "$count"
