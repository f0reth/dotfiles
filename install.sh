#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# dotfiles ディレクトリのパス
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# システムアップデート
log_info "システムをアップデート中..."
sudo apt update && sudo apt upgrade -y

# 基本的な依存関係をインストール
log_info "基本的な依存関係をインストール中..."
sudo apt install -y curl wget git unzip gpg ca-certificates

# zsh のインストール
log_info "zsh をインストール中..."
sudo apt install -y zsh

# デフォルトシェルを zsh に変更
log_info "デフォルトシェルを zsh に変更中..."
chsh -s "$(which zsh)"

# mise のインストール
log_info "mise をインストール中..."
curl https://mise.run | sh

# mise で管理するツール (Neovim, tree-sitter, Starship, Sheldon, eza, ripgrep, bat, lazygit, uv, bun など) のインストール
# link.sh の実行前でも動くよう、dotfiles 内の設定ファイルを直接参照する
log_info "mise でツールをインストール中..."
export MISE_GLOBAL_CONFIG_FILE="$DOTFILES_DIR/mise/config.toml"
~/.local/bin/mise install

# win32yank のインストール (WSL のみ)
# .zshenv で Windows 側の PATH を除外しているため、Neovim がクリップボード連携に使えるよう ~/.local/bin に配置する
if grep -qi microsoft /proc/version; then
    log_info "win32yank をインストール中..."
    WIN32YANK_TMP="$(mktemp -d)"
    curl -fsSL -o "$WIN32YANK_TMP/win32yank.zip" https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
    unzip -o -q "$WIN32YANK_TMP/win32yank.zip" win32yank.exe -d "$WIN32YANK_TMP"
    install -m 0755 "$WIN32YANK_TMP/win32yank.exe" ~/.local/bin/win32yank.exe
    rm -rf "$WIN32YANK_TMP"
fi

# Docker のインストール
log_info "Docker をインストール中..."
# 古いバージョンを削除
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Docker の公式 GPG キーを追加
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Docker リポジトリを追加
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker グループに現在のユーザーを追加
log_info "Docker グループに現在のユーザーを追加中..."
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER

# Docker サービスを有効化して起動
sudo systemctl enable docker
sudo systemctl start docker

sudo apt autoremove -y && sudo apt autoclean -y

log_info "インストールが完了しました！"
log_warn "注意: Docker を sudo なしで実行するには、ログアウトして再度ログインする必要があります。"
log_warn "注意: zsh をデフォルトシェルとして使用するには、ログアウトして再度ログインする必要があります。"

echo ""
echo -e "${GREEN}インストールされたツールのバージョン:${NC}"
echo "zsh: $(zsh --version)"
echo "mise: $(~/.local/bin/mise --version)"
~/.local/bin/mise ls --current
echo "docker: $(docker --version)"
