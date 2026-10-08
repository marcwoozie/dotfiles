# fish 設定のエントリーポイント
# 新しいマシンでは scripts/fish-setup.sh がこのファイルを ~/.config/fish/config.fish へリンクする。
# 各ツールは未インストールでもエラーにならないよう存在チェックを入れている。

if status is-interactive
    # Homebrew
    for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew
        if test -x $brew_bin
            eval ($brew_bin shellenv)
            break
        end
    end
end

# flutter
if test -d $HOME/bin/flutter/bin
    set -x PATH $HOME/bin/flutter/bin $PATH
end

# rbenv
if test -d $HOME/.rbenv/bin
    set -x PATH $HOME/.rbenv/bin $PATH
end
if status --is-interactive; and command -q rbenv
    source (rbenv init - fish | psub)
end

# nvm
if test -d $HOME/.nvm/bin
    set -x PATH $HOME/.nvm/bin $PATH
end

# dart (pub) のグローバル実行ファイル
if test -d $HOME/.pub-cache/bin
    set -x PATH $HOME/.pub-cache/bin $PATH
end

# anyenv
if test -d $HOME/.anyenv
    if test -d $HOME/.anyenv/envs/nodenv/bin
        set -x PATH $HOME/.anyenv/envs/nodenv/bin $PATH
    end
    set -x PATH $HOME/.anyenv/bin $PATH
    anyenv init - fish | source
    for D in (ls $HOME/.anyenv/envs)
        set -x PATH $HOME/.anyenv/envs/$D/shims $PATH
    end
end

# goenv
set -x GOENV_ROOT $HOME/.goenv
if test -d $GOENV_ROOT/bin
    set -x PATH $GOENV_ROOT/bin $PATH
end
if command -q goenv
    goenv init - fish | source
end

function push_to_top -d "今の画面内容を上に押し出してプロンプトを最上部に戻す"
    # 1. 画面の高さ分だけ改行して、今の内容をすべて上に押し出す
    printf (string repeat -n $LINES "\n")

    # 2. カーソルを「画面の左上（1行目の1列目）」に移動させる
    # \e[H はカーソルをホーム位置へ移動させるエスケープシーケンス
    printf "\e[H"

    # 3. 入力中の文字列を再描画する
    commandline -f repaint
end

if status is-interactive
    # Ctrl + L に割り当て
    bind \cl push_to_top
end
