#!/bin/bash

set -e

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_success() {
    echo -e "${BLUE}[SUCCESS]${NC} $1"
}

# dotfiles ディレクトリのパス
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# バックアップディレクトリの作成
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
log_info "バックアップディレクトリを作成: $BACKUP_DIR"

# シンボリックリンクを作成する関数
create_symlink() {
    local source="$1"
    local target="$2"

    # ソースファイルが存在しない場合はスキップ
    if [ ! -e "$source" ]; then
        log_warn "ソースファイルが存在しません: $source"
        return
    fi

    # ターゲットディレクトリを作成
    local target_dir=$(dirname "$target")
    mkdir -p "$target_dir"

    # 既存のファイル/リンクがある場合はバックアップ
    if [ -e "$target" ] || [ -L "$target" ]; then
        log_warn "既存のファイルをバックアップ: $target"
        mv "$target" "$BACKUP_DIR/"
    fi

    # シンボリックリンクを作成
    ln -sf "$source" "$target"
    log_success "リンク作成: $target -> $source"
}

# メイン処理
log_info "dotfiles のシンボリックリンクを作成中..."
log_info "dotfiles ディレクトリ: $DOTFILES_DIR"

# zsh
create_symlink "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
create_symlink "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
create_symlink "$DOTFILES_DIR/.zsh_aliases" "$HOME/.zsh_aliases"

# Starship
create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

# Sheldon
create_symlink "$DOTFILES_DIR/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

log_info "シンボリックリンクの作成が完了しました！"
log_info "元のファイルは $BACKUP_DIR にバックアップされています。"

echo ""
echo -e "${GREEN}次のステップ:${NC}"
echo "1. zsh を起動して設定を確認: zsh"
echo "2. 必要に応じて追加の設定を行ってください"
echo "3. バックアップが不要な場合は削除: rm -rf $BACKUP_DIR"
