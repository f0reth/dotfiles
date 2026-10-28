# ------------------------------
# 基本設定
# ------------------------------
# 履歴設定
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY          # 履歴を共有
setopt HIST_IGNORE_ALL_DUPS   # 重複を記録せず、古い重複を削除
setopt HIST_FIND_NO_DUPS      # 履歴検索で重複を表示しない
setopt HIST_IGNORE_SPACE      # スペースで始まるコマンドは履歴に追加しない
setopt HIST_SAVE_NO_DUPS      # 保存時に重複を削除
setopt HIST_REDUCE_BLANKS     # 余分な空白を削除

# ディレクトリ移動
setopt AUTO_CD                # cdなしでディレクトリ移動
setopt AUTO_PUSHD             # 自動的にディレクトリスタックに追加
setopt PUSHD_IGNORE_DUPS      # 重複したディレクトリをスタックに追加しない

# 補完
setopt MAGIC_EQUAL_SUBST      # =以降でも補完
setopt COMPLETE_IN_WORD       # 語の途中でも補完

# その他
setopt CORRECT                # コマンドのスペルミス訂正
setopt NO_BEEP                # ビープ音を鳴らさない
setopt INTERACTIVE_COMMENTS   # コマンドラインでの#以降をコメントとして扱う

# ------------------------------
# 補完システム
# ------------------------------
zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"

# 生成した補完ファイルの保存先（Tab を押したときに読み込まれる）
zcompdir="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
fpath=($zcompdir $fpath)

# uv / uvx の補完ファイルは、uv のインストール・更新時のみ生成
if (( $+commands[uv] )) && [[ ! -s $zcompdir/_uv || $commands[uv] -nt $zcompdir/_uv ]]; then
  mkdir -p "$zcompdir"
  uv generate-shell-completion zsh > "$zcompdir/_uv"
  uvx --generate-shell-completion zsh > "$zcompdir/_uvx"
  rm -f "$zcompdump"  # 新しい補完ファイルを compinit に認識させる
fi

# 通常はキャッシュを使って高速に初期化し、セキュリティチェックは1日1回だけ行う
autoload -Uz compinit
stale_zcompdump=($zcompdump(N.mh+24))
if [[ ! -f $zcompdump || -n $stale_zcompdump ]]; then
  compinit -d "$zcompdump"
  touch "$zcompdump"
else
  compinit -C -d "$zcompdump"
fi
unset zcompdump zcompdir stale_zcompdump

eval "$(dircolors -b)"
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

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
# エイリアス
# ------------------------------
[[ -f "$HOME/.zsh_aliases" ]] && source "$HOME/.zsh_aliases"

# ------------------------------
# 関数
# ------------------------------
# eza でツリー表示（第1引数が数字なら階層の深さとして扱う）
function lt() {
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    eza --tree --level "$1" "${@:2}"
  else
    eza --tree "$@"
  fi
}

# ------------------------------
# プラグインマネージャー (Sheldon)
# ------------------------------
if (( $+commands[sheldon] )); then
  sheldon_cache="${XDG_CACHE_HOME:-$HOME/.cache}/sheldon.zsh"
  sheldon_toml="$HOME/.config/sheldon/plugins.toml"
  # キャッシュがない、またはキャッシュが古い場合にキャッシュを作成
  if [[ ! -r "$sheldon_cache" || "$sheldon_toml" -nt "$sheldon_cache" ]]; then
    mkdir -p "${sheldon_cache:h}"
    sheldon source > "$sheldon_cache"
  fi
  source "$sheldon_cache"
  unset sheldon_cache sheldon_toml
fi

# ------------------------------
# ツール初期化
# ------------------------------
# Starship
if (( $+commands[starship] )); then
  eval "$(starship init zsh)"
fi

# mise
if (( $+commands[mise] )); then
  eval "$(mise activate zsh)"
fi
