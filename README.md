# my dotfiles

## 新しいマシンのセットアップ

```sh
git clone git@github.com:marcwoozie/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles

bash scripts/fish-setup.sh   # fish（シェル）
bash scripts/tmux-setup.sh   # tmux
bash scripts/nvim-setup.sh   # Neovim
```

Homebrew が未導入の場合は先に入れておく。

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

## fish

管理対象は `.config/fish/` 以下。

| パス | 内容 |
| --- | --- |
| `config.fish` | PATH・各バージョンマネージャの初期化・キーバインド |
| `fish_plugins` | fisher が管理するプラグイン一覧 |
| `conf.d/*.fish` | 起動時に読み込む追加設定 |
| `theme/tide.fish` | tide プロンプトと配色のユニバーサル変数スナップショット |

fisher がインストールする `functions/` `completions/` や、`fish_variables`・`fish_history`
といった実行時の状態は `.gitignore` で除外している（セットアップ時に再生成される）。

### 任意の依存ツール

`config.fish` は以下が未インストールでもエラーにならないようになっている。
使うものだけ入れればよい。

```sh
brew install anyenv rbenv ruby-build goenv
```

- `anyenv` — nodenv / phpenv などのバージョンマネージャ群
- `rbenv` — Ruby
- `goenv` — Go
- `flutter` — `~/bin/flutter` に配置すると PATH に入る
- `uv` — インストールすると `conf.d/uv.fish` 経由で環境が読み込まれる

### Setup

```sh
bash scripts/fish-setup.sh
```

以下を順に行う。

1. fish を Homebrew でインストール（未インストール時のみ）
2. 設定ファイルを `~/.config/fish/` へシンボリックリンク
3. fisher を導入し `fish_plugins` のプラグインをインストール
4. `theme/tide.fish` を適用してプロンプトと配色を再現
5. `/etc/shells` に登録し、ログインシェルを fish に変更（`sudo` を求められる）

Dry-run:

```sh
bash scripts/fish-setup.sh --dry-run
```

Options:

```sh
bash scripts/fish-setup.sh --skip-install   # fish のインストールをしない
bash scripts/fish-setup.sh --skip-shell     # ログインシェルを変更しない
bash scripts/fish-setup.sh --skip-plugins   # fisher / プラグインを入れない
bash scripts/fish-setup.sh --skip-theme     # tide / 配色を適用しない
```

### プロンプト設定を更新したとき

`tide configure` などでユニバーサル変数を変えたら、スナップショットを再生成してコミットする。

```sh
bash scripts/fish-export-theme.sh
```

## tmux

tmux 設定は `.config/tmux/.tmux.conf`。

### Setup

```sh
bash scripts/tmux-setup.sh
```

Dry-run:

```sh
bash scripts/tmux-setup.sh --dry-run
```

Options:

```sh
# Do not install TPM
bash scripts/tmux-setup.sh --skip-tpm

# Do not reload running tmux
bash scripts/tmux-setup.sh --skip-reload
```

セットアップ後、tmux 内で `prefix + I` を押して TPM でプラグインをインストールする。

## Neovim

管理対象は `.config/nvim/` 以下（[LazyVim](https://www.lazyvim.org/) ベース）。

| パス | 内容 |
| --- | --- |
| `init.lua` | エントリーポイント |
| `lua/config/` | lazy.nvim のブートストラップ・オプション・キーマップ・オートコマンド |
| `lua/plugins/` | プラグインの追加・上書き設定 |
| `lazy-lock.json` | プラグインのロック済みバージョン |
| `lazyvim.json` | 有効にしている LazyVim extras |

プラグイン本体や Mason が入れるツールは `~/.local/share/nvim/` に置かれ、リポジトリには含めない
（セットアップ時に再生成される）。

### Setup

```sh
bash scripts/nvim-setup.sh
```

以下を順に行う。

1. neovim を Homebrew でインストール（未インストール時のみ）
2. LazyVim が利用する外部ツール（`ripgrep` `fd` `fzf` `lazygit` `tree-sitter-cli`）をインストール
3. `~/.config/nvim` を `.config/nvim` へシンボリックリンク（既存の設定は `.bak.<日時>` に退避）
4. `lazy-lock.json` のバージョンでプラグインをインストール（`:Lazy restore`）

Dry-run:

```sh
bash scripts/nvim-setup.sh --dry-run
```

Options:

```sh
bash scripts/nvim-setup.sh --skip-install   # neovim のインストールをしない
bash scripts/nvim-setup.sh --skip-deps      # 外部ツールを入れない
bash scripts/nvim-setup.sh --skip-plugins   # プラグインを入れない
```

LSP サーバーやフォーマッタ（Mason）、treesitter のパーサーは初回の `nvim` 起動時に自動で導入される。
アイコン表示には Nerd Font が必要。

### プラグインを更新したとき

`:Lazy update` などで `lazy-lock.json` が変わったら、あわせてコミットする。
