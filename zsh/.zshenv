# ========================================
# Zsh Environment Variables
# ========================================
# このファイルは全てのzshセッションで最初に読み込まれます

# XDG Base Directory
# export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
# export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
# export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
# export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# デフォルトエディタ
export EDITOR='nvim'
export VISUAL='nvim'

# 言語設定
# export LANG=ja_JP.UTF-8
# export LC_ALL=ja_JP.UTF-8

# PATH設定
# typeset -U path  # 重複を自動削除
# path=(
#     $HOME/.local/bin(N-/)
#     # $HOME/.cargo/bin(N-/)
#     $HOME/.bun/bin(N-/)
#     $path
# )
