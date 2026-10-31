# ログインシェルで読み込まれる (このファイルがあると ~/.profile は読まれない)
# 環境変数も含めて全ての設定は .bashrc にあるので、読み込むだけにする
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"
