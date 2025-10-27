# ========================================
# Zsh Configuration
# ========================================

# ------------------------------
# 環境変数
# ------------------------------
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"

# ------------------------------
# 基本設定
# ------------------------------
# 履歴設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # 履歴を共有
setopt HIST_IGNORE_DUPS       # 重複を記録しない
setopt HIST_IGNORE_ALL_DUPS   # 古い重複を削除
setopt HIST_FIND_NO_DUPS      # 履歴検索で重複を表示しない
setopt HIST_IGNORE_SPACE      # スペースで始まるコマンドは履歴に追加しない
setopt HIST_SAVE_NO_DUPS      # 保存時に重複を削除
setopt HIST_REDUCE_BLANKS     # 余分な空白を削除

# ディレクトリ移動
#setopt AUTO_CD                # cdなしでディレクトリ移動
#setopt AUTO_PUSHD             # 自動的にディレクトリスタックに追加
#setopt PUSHD_IGNORE_DUPS      # 重複したディレクトリをスタックに追加しない

# 補完
setopt AUTO_MENU              # TAB連打で補完候補を順に表示
setopt AUTO_PARAM_SLASH       # ディレクトリ名の補完で末尾に/を追加
setopt MAGIC_EQUAL_SUBST      # =以降でも補完
setopt COMPLETE_IN_WORD       # 語の途中でも補完

# その他
setopt CORRECT                # コマンドのスペルミス訂正
setopt NO_BEEP                # ビープ音を鳴らさない
setopt INTERACTIVE_COMMENTS   # コマンドラインでの#以降をコメントとして扱う

# ------------------------------
# 補完システム
# ------------------------------
#autoload -Uz compinit
#compinit

# 補完候補をキャッシュ
#zstyle ':completion:*' use-cache yes
#zstyle ':completion:*' cache-path ~/.zsh/cache

# 補完候補を詳細表示
#zstyle ':completion:*' verbose yes
#zstyle ':completion:*' menu select

# 大文字小文字を区別しない
#zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# 補完候補に色をつける
#zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# ------------------------------
# エイリアス
# ------------------------------
if [ -f "$HOME/.zsh_aliases" ]; then
    source "$HOME/.zsh_aliases"
fi

# ------------------------------
# 関数
# ------------------------------
# mkdirして移動
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# ファイルマネージャー（yaziで開いたディレクトリに移動）
# function yy() {
#     local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
#     yazi "$@" --cwd-file="$tmp"
#     if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
#         cd -- "$cwd"
#     fi
#     rm -f -- "$tmp"
# }

# ------------------------------
# プラグインマネージャー (Sheldon)
# ------------------------------
# ファイル名を変数に入れる
cache_dir=${XDG_CACHE_HOME:-$HOME/.cache}
sheldon_cache="$cache_dir/sheldon.zsh"
sheldon_toml="$HOME/.config/sheldon/plugins.toml"
# キャッシュがない、またはキャッシュが古い場合にキャッシュを作成
if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
    mkdir -p $cache_dir
    sheldon source > $sheldon_cache
fi
source "$sheldon_cache"
# 使い終わった変数を削除
unset cache_dir sheldon_cache sheldon_toml

# ------------------------------
# ツール初期化
# ------------------------------
# Starship
eval "$(starship init zsh)"

# mise
eval "$(~/.local/bin/mise activate zsh)"

# uv
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"

# ------------------------------
# キーバインド
# ------------------------------
# Emacs風キーバインド
bindkey -e

# 履歴検索
autoload -Uz history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# ------------------------------
# その他
# ------------------------------
# 色を使えるようにする
autoload -Uz colors
colors
