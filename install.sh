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

# Starship のインストール
log_info "Starship をインストール中..."
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Sheldon のインストール
log_info "Sheldon をインストール中..."
curl --proto '=https' -fLsS https://rossmacarthur.github.io/install/crate.sh \
    | bash -s -- --repo rossmacarthur/sheldon --to ~/.local/bin

# eza のインストール
log_info "eza をインストール中..."
sudo mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# ripgrep のインストール
log_info "ripgrep をインストール中..."
sudo apt install -y ripgrep

# bat のインストール
log_info "bat をインストール中..."
sudo apt install -y bat

# Neovim のインストール (最新版)
log_info "Neovim をインストール中..."
wget https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz
sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
rm nvim-linux-x86_64.tar.gz
sudo ln /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# mise のインストール
log_info "mise をインストール中..."
curl https://mise.run | sh

# uv のインストール
log_info "uv をインストール中..."
curl -LsSf https://astral.sh/uv/install.sh | sh

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
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

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
echo "starship: $(starship --version)"
echo "sheldon: $(~/.local/bin/sheldon --version)"
echo "eza: $(eza --version | head -n 1)"
echo "ripgrep: $(rg --version | head -n 1)"
echo "bat: $(batcat --version)"
echo "neovim: $(/opt/nvim-linux-x86_64/bin/nvim --version | head -n 1)"
echo "mise: $(~/.local/bin/mise --version)"
echo "uv: $(~/.local/bin/uv --version)"
echo "docker: $(docker --version)"
