# ==============================
# 環境変数 (zsh の .zshenv に相当)
# ==============================
# bash には全てのセッションで読まれるファイルが無いため、.bashrc の先頭で設定する
# (ログインシェルは .bash_profile 経由で、ssh でのコマンド実行もこのファイルを読む)

# デフォルトエディタ
export EDITOR='nvim'
export VISUAL='nvim'

# PATH設定
# 存在するディレクトリのみ追加し、重複は削除する
# WSL が追加する Windows 側のPATH (/mnt/c/...) はコマンド検索が遅くなるため除外し、VS Code と Zed だけ残す
__path_new=
__path_add() {
  [[ -d "$1" && ":$__path_new:" != *":$1:"* ]] && __path_new+="${__path_new:+:}$1"
}
# mise のツールを非対話シェル (スクリプトやエディタからの起動) でも使えるようにする
# 対話シェルでは後の mise activate が実体のパスを前に追加するのでそちらが優先される
__path_add "$HOME/.local/share/mise/shims"
__path_add "$HOME/.local/bin"
__path_add "$HOME/.cargo/bin"  # rustup (cargo / rustc など)
__path_add "$HOME/.bun/bin"
IFS=: read -ra __path_old <<< "$PATH"
for __path_dir in "${__path_old[@]}"; do
  [[ "$__path_dir" == /mnt/c/* ]] || __path_add "$__path_dir"
done
__path_add /usr/local/go/bin
__path_add "$HOME/go/bin"
__path_add "/mnt/c/Users/$USER/AppData/Local/Programs/Microsoft VS Code/bin"
__path_add "/mnt/c/Users/$USER/AppData/Local/Programs/Zed/bin"
export PATH="$__path_new"
unset -f __path_add
unset __path_new __path_old __path_dir

# 以降は対話シェルのみ
[[ $- == *i* ]] || return

# ==============================
# ble.sh (Bash Line Editor)
# ==============================
# zsh-autosuggestions / fast-syntax-highlighting / fzf-tab に相当する機能を提供する
# 最初に読み込み (--attach=none)、全ての設定が終わった最後に ble-attach する
if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" ]]; then
  source -- "${XDG_DATA_HOME:-$HOME/.local/share}/blesh/ble.sh" --attach=none
fi

# ------------------------------
# 基本設定
# ------------------------------
# 履歴設定
HISTFILE=~/.bash_history
HISTSIZE=10000
HISTFILESIZE=10000
HISTCONTROL=ignorespace:erasedups  # スペースで始まるコマンドは記録せず、古い重複を削除
shopt -s histappend                # 終了時に履歴を上書きせず追記
# 履歴の共有は ble.sh があれば bleopt history_share で、無ければ PROMPT_COMMAND で行う (下の ble.sh の設定を参照)

# ディレクトリ移動
shopt -s autocd                    # cdなしでディレクトリ移動
shopt -s cdspell dirspell          # ディレクトリ名のスペルミス訂正 (zsh の CORRECT に相当)

# その他
shopt -s interactive_comments      # コマンドラインでの#以降をコメントとして扱う
bind 'set bell-style none'         # ビープ音を鳴らさない

# ------------------------------
# mise
# ------------------------------
# mise で入れたツール (uv, starship, fzf など) を以降で使うため最初に読み込む
if command -v mise >/dev/null; then
  eval "$(mise activate bash)"
fi

# ------------------------------
# 補完システム
# ------------------------------
# bash-completion (zsh-completions に相当)
# コマンドごとの補完定義は初回 Tab 時に遅延読み込みされるため、起動は遅くならない
if [[ -z "${BASH_COMPLETION_VERSINFO-}" && -f /usr/share/bash-completion/bash_completion ]] && ! shopt -oq posix; then
  source /usr/share/bash-completion/bash_completion
fi

# uv / uvx の補完ファイルは、uv のインストール・更新時のみ生成
# bash-completion が初回 Tab 時にこのディレクトリから遅延読み込みする
__compdir="${BASH_COMPLETION_USER_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion}/completions"
if __uv="$(type -P uv)" && [[ ! -s "$__compdir/uv" || "$__uv" -nt "$__compdir/uv" ]]; then
  mkdir -p "$__compdir"
  uv generate-shell-completion bash > "$__compdir/uv"
  uvx --generate-shell-completion bash > "$__compdir/uvx"
fi
unset __compdir __uv

command -v dircolors >/dev/null && eval "$(dircolors -b)"
bind 'set completion-ignore-case on'  # 大文字小文字を区別しない
bind 'set colored-stats on'           # 補完候補を LS_COLORS で色付け

# ------------------------------
# キーバインド
# ------------------------------
# Emacs風キーバインド
set -o emacs

# ------------------------------
# エイリアス
# ------------------------------
# zsh と共通 (~/.bash_aliases は zsh/.zsh_aliases へのリンク)
[[ -f "$HOME/.bash_aliases" ]] && source "$HOME/.bash_aliases"

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

# Yazi (終了時のディレクトリに移動する。y で起動)
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# ------------------------------
# ble.sh の設定 / ble.sh が無いときの代替
# ------------------------------
if [[ ${BLE_VERSION-} ]]; then
  bleopt history_share=1                  # 履歴を共有
  bleopt edit_bell=                       # ベルを鳴らさない
  bleopt filename_ls_colors="$LS_COLORS"  # ファイル名を LS_COLORS で色付け

  # 履歴検索 (入力済みの文字で前方一致検索し、カーソルは行末へ)
  ble-bind -f C-p 'history-search-backward hide-status:immediate-accept:empty=history-move:point=end'
  ble-bind -f C-n 'history-search-forward hide-status:immediate-accept:empty=history-move:point=end'

  # fzf (Ctrl-R: 履歴検索, Ctrl-T: ファイル検索, Alt-C: ディレクトリ移動, Tab: fzf で補完候補を選択)
  # ble.sh 使用時は fzf --bash を直接 eval せず、ble.sh の連携モジュールを使う (-d: 起動後に非同期で読み込む)
  if command -v fzf >/dev/null; then
    ble-import -d integration/fzf-completion
    ble-import -d integration/fzf-key-bindings
    ble-import -d integration/fzf-menu
  fi
else
  # 履歴を共有
  PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

  # 履歴検索 (入力済みの文字で前方一致検索)
  bind '"\C-p": history-search-backward'
  bind '"\C-n": history-search-forward'

  # fzf (Ctrl-R: 履歴検索, Ctrl-T: ファイル検索, Alt-C: ディレクトリ移動)
  if command -v fzf >/dev/null; then
    eval "$(fzf --bash)"
  fi
fi

# ------------------------------
# ツール初期化
# ------------------------------
# Starship
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi

# ble.sh を有効化 (最後に実行する)
[[ ! ${BLE_VERSION-} ]] || ble-attach
