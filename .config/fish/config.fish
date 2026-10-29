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

# herdr: タブ名をカレントディレクトリ名と同期する（herdr 内のシェルでのみ有効）
if status is-interactive; and set -q HERDR_TAB_ID; and command -q herdr
    function __herdr_sync_tab_name --on-variable PWD -d "herdr のタブ名をカレントディレクトリ名にする"
        set -l name (path basename $PWD)
        test "$PWD" = "$HOME"; and set name "~"
        # 数 ms で返るので同期実行する（バックグラウンドだと連続 cd で順序が入れ替わる）
        command herdr tab rename $HERDR_TAB_ID $name >/dev/null 2>&1
    end
    __herdr_sync_tab_name
end

# herdr: ~/workspace 配下のリポジトリを選び、同名の space があれば移動、無ければ作成する
# herdr の prefix+s ポップアップから fish -c herdr-repo で呼ばれる
function herdr-repo -d "リポジトリを選んで herdr の space を開く"
    set -l dir (path filter -d $HOME/workspace/* | fzf --reverse --prompt 'repo> ' --delimiter / --with-nth -1)
    test -n "$dir"; or return
    set -l name (path basename $dir)
    set -l id (herdr workspace list | jq -r --arg n $name '.result.workspaces[] | select(.label == $n) | .workspace_id' | head -1)
    if test -n "$id"
        herdr workspace focus $id >/dev/null
    else
        herdr workspace create --cwd $dir --label $name --focus >/dev/null
    end
end
