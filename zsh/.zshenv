# このファイルは全てのzshセッションで最初に読み込まれます

# デフォルトエディタ
export EDITOR='nvim'
export VISUAL='nvim'

# Ubuntu の /etc/zsh/zshrc で compinit を実行しない（.zshrc で高速版を実行）
skip_global_compinit=1

# PATH設定
# (N-/) : 存在するディレクトリのみ追加
# WSL が追加する Windows 側のPATH (/mnt/c/...) はコマンド検索が遅くなるため除外し、VS Code だけ残す
typeset -U path  # 重複を自動削除
path=(
    $HOME/.local/bin(N-/)
    $HOME/.bun/bin(N-/)
    ${path:#/mnt/c/*}
    /usr/local/go/bin(N-/)
    $HOME/go/bin(N-/)
    "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"(N-/)
)
export PATH
