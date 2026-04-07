# CLAUDE.md

このファイルは、このリポジトリでコード作業を行う Claude Code（claude.ai/code）へのガイダンスを提供します。

## リポジトリ概要

このリポジトリは **marcwoozie** のドットファイル設定を管理するもので、Neovim（LazyVim 経由）と Wezterm ターミナルエミュレータの設定を含んでいます。macOS システム間で一貫性のあるモダンな開発環境を維持することが主な目的です。

**主要スタック：**
- Neovim with LazyVim（Lua 設定）
- Wezterm ターミナルエミュレータ
- 全ツール共通の Tokyo Night テーマ
- 透過背景スタイリング

## プロジェクト構造

```
.config/
├── nvim/                           # Neovim 設定（LazyVim ベース）
│   ├── init.lua                    # エントリーポイント
│   ├── lua/config/                 # コア設定
|   │   ├── options.lua             # Neovim オプション
│   │   ├── keymaps.lua             # キーマップ
│   │   └── autocmds.lua            # オートコマンド
│   ├── lua/plugins/                # プラグイン設定
│   │   ├── transparent.lua         # Tokyo Night 透過設定
│   │   └── example.lua             # カスタムプラグイン用テンプレート
│   ├── lazy-lock.json              # ロック済みプラグインバージョン
│   ├── lazyvim.json                # LazyVim 設定
│   └── stylua.toml                 # Lua フォーマッタ設定
│
└── wezterm/                        # Wezterm ターミナル設定
    ├── wezterm.lua                 # メイン設定（不透明度、フォント、色）
    └── keybinds.lua                # キーバインディング（ワークスペース、タブ、ペイン）
```

## よく使うタスク

### Neovim 設定

**新しいプラグインを追加する：**
1. `lua/plugins/` に新しいファイルを作成（例：`lua/plugins/myplugin.lua`）
2. Lazy.nvim フォーマットを使ってプラグイン仕様を定義
3. Neovim 内で `:Lazy` を実行して同期と検証を行う
4. 変更を `lazy-lock.json` の更新と共にコミット

**プラグイン構造の例：**
```lua
return {
  "github-user/repo-name",
  event = "VeryLazy",  -- 遅延ロードイベント
  config = function()
    -- セットアップコード
  end,
}
```

**プラグインを更新：**
```bash
nvim -c "Lazy update" -c "qa"
```

**Lua ファイルをフォーマット：**
```bash
stylua lua/
```

**主要なインストール済みプラグイン：**
- `blink.cmp` - 補完エンジン
- `conform.nvim` - コードフォーマッタ
- `nvim-lspconfig` + `mason.nvim` - LSP 管理
- `nvim-treesitter` - 構文木解析
- `gitsigns.nvim` - Git 統合
- `tokyonight.nvim` - カラースキーム

### Wezterm 設定

**メイン設定ファイル：** `.config/wezterm/wezterm.lua`

**主要な設定：**
- フォント：Hack 11.0pt
- 不透明度：80%
- カラースキーム：Tokyo Night
- リーダーキー：`CTRL+q`（タイムアウト: 2000ms）
- スクロールバッファ：5000 行

**Wezterm キーバインディング（`keybinds.lua` でカスタマイズ可能）：**
- ワークスペース：`Leader+w`（選択）/ `Leader+Shift+W`（作成）
- タブ：`Cmd+T`（新規）/ `Cmd+W`（閉じる）/ `Ctrl+Tab`（切り替え）
- ペイン：`Leader+d`（縦分割）/ `Leader+r`（横分割）/ `Leader+hjkl`（移動）
- フォント：`Ctrl++` / `Ctrl+-` / `Ctrl+0`（調整/リセット）
- コピーモード：`Leader+[`（Vi 風ナビゲーション開始）

**Wezterm 設定をリロード：** `Cmd+Shift+R`

## 重要な設定詳細

### LazyVim ブートストラップ

`init.lua` エントリーポイントは `lua/config/lazy.lua` をロードします。これにより以下が実行されます：
- Lazy.nvim プラグインマネージャーの初期化
- デフォルトカラースキームを `tokyonight` に設定
- 組み込みプラグインを無効化：gzip、tarPlugin、tohtml、tutor、zipPlugin
- プラグイン更新の自動チェックを有効化

### 透過設定

透過性は `lua/plugins/transparent.lua` で設定されます：
- Tokyo Night テーマで `transparent = true`
- サイドバーとフロートは透明背景
- macOS のバックドロップぼかしに対応

### Git 統合

- Gitsigns.nvim が git サインをガターに表示
- 最近のコミットはエディタ/ターミナル設定の調整に焦点
- main ブランチが本番用、test ブランチが実験用

## リント・フォーマッティング

**Mason で管理されるツール：**
- `stylua` - Lua フォーマッタ（設定：`stylua.toml`）
- `shellcheck` - Shell リンター
- `shfmt` - Shell フォーマッタ
- `flake8` - Python リンター

**Neovim でのリント・フォーマット実行：**
- 現在のファイルをフォーマット：`:Format`（Conform.nvim）
- ファイルをリント：`:Lint`（nvim-lint）

## 設定の拡張

**カスタムキーマップを追加：**
- エディタバインディング：`lua/config/keymaps.lua` を編集
- ターミナルバインディング：`.config/wezterm/keybinds.lua` を編集

**カスタムオプションを追加：**
- Neovim 設定：`lua/config/options.lua` を編集
- ターミナル設定：`.config/wezterm/wezterm.lua` を編集

**対応ファイルタイプ：**
- TypeScript/JavaScript
- Python
- Lua
- Bash/Shell
- JSON/YAML
- Markdown
- HTML/CSS

## バージョン管理ノート

- リポジトリ：`git@github.com:marcwoozie/dotfiles.git`
- main ブランチはアクティブに保守中
- コミットは細粒度で特定の設定変更に焦点
- `.gitignore` はプラットフォーム固有のツールを除外（anyenv、firebase、iTerm2、Raycast など）
