#!/bin/bash
#
# Linux (Ubuntu / WSL) 開発環境セットアップスクリプト (apt + mise)
#
# 1. apt でシステムパッケージ (zsh, bash-completion, ビルドツールなど) をインストール
# 2. デフォルトシェルを zsh に変更
# 3. mise が無ければインストール
# 4. 設定をシンボリックリンクで適用 (既存のものは <パス>.bak_日時 に退避)
# 5. mise install でツールを、ya pkg install で Yazi のプラグインをインストール
# 6. rustup で Rust (stable) と rust-analyzer をインストール
# 7. vcpkg (C++ のパッケージマネージャー) をインストール
# 8. bash 用の ble.sh をインストール
# 9. win32yank を配置 (WSL のみ)
# 10. Docker をインストール
#
# 何度実行しても同じ結果になるようにしている (リンク済み・インストール済みのものは省略)
#
# 使い方:
#   ./install.sh              # すべて実行
#   ./install.sh --skip-apt   # apt と Docker を省略 (設定のリンクと mise だけ反映したいとき)

set -euo pipefail

SKIP_APT=false
for arg in "$@"; do
    case "$arg" in
        --skip-apt) SKIP_APT=true ;;
        -h | --help)
            sed -n '3,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "不明なオプション: $arg" >&2
            exit 1
            ;;
    esac
done

# 色の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ログ関数
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# dotfiles ディレクトリのパス
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MISE="$HOME/.local/bin/mise"

# root で実行すると chsh や docker グループの対象が root になるため拒否する
if [ "$(id -u)" -eq 0 ]; then
    log_error "root ではなく通常のユーザーで実行してください (必要なところは sudo を使います)"
    exit 1
fi

is_wsl() {
    grep -qi microsoft /proc/version 2>/dev/null
}

# ------------------------------
# apt
# ------------------------------
install_apt_packages() {
    log_info "システムをアップデート中..."
    sudo apt-get update
    sudo apt-get upgrade -y

    # build-essential: Neovim の Treesitter パーサーのビルドと、Rust のリンカー (cc) に必要
    # bash-completion: bash の補完定義 / xz-utils: ble.sh の展開に必要
    log_info "基本的な依存関係をインストール中..."
    sudo apt-get install -y zsh bash-completion curl wget git unzip xz-utils gpg ca-certificates build-essential

    # C / C++ (gcc / g++ は build-essential に含まれる。CMake / Ninja は mise で入れる)
    # clangd / clang-format / clang-tidy: エディタ (Neovim / VS Code) の補完・フォーマット・静的解析
    # zip / pkg-config: vcpkg がライブラリのビルドに使う
    log_info "C / C++ の開発ツールをインストール中..."
    sudo apt-get install -y clang clangd clang-format clang-tidy gdb lldb zip pkg-config
}

# ------------------------------
# デフォルトシェル
# ------------------------------
set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh || true)"
    if [ -z "$zsh_path" ]; then
        log_warn "zsh が見つからないため、デフォルトシェルの変更を省略します"
        return
    fi
    if [ "$(getent passwd "$USER" | cut -d: -f7)" = "$zsh_path" ]; then
        log_success "デフォルトシェルは zsh です"
        return
    fi
    log_info "デフォルトシェルを zsh に変更中..."
    chsh -s "$zsh_path"
    log_success "デフォルトシェルを zsh に変更しました (再ログイン後に反映)"
}

# ------------------------------
# mise
# ------------------------------
install_mise() {
    if [ -x "$MISE" ]; then
        log_success "mise はインストール済みです"
        return
    fi
    log_info "mise をインストール中..."
    curl -fsSL https://mise.run | sh
    log_success "mise をインストールしました"
}

install_mise_tools() {
    # Neovim, tree-sitter, Starship, Sheldon, eza, ripgrep, bat, lazygit, uv, bun など
    log_info "mise install を実行します..."
    "$MISE" install
    log_success "mise のツールをインストールしました"
}

# ------------------------------
# 設定のリンク
# ------------------------------
# 既存のファイル/ディレクトリを <パス>.bak_日時 に退避する
backup_item() {
    local path="$1"
    local backup
    backup="$path.bak_$(date +%Y%m%d_%H%M%S)"
    mv "$path" "$backup"
    log_warn "既存のファイルをバックアップ: $backup"
}

# シンボリックリンクを作成する (リンク済みなら何もしない)
create_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_warn "ソースファイルが存在しません: $source"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        log_success "リンク済み: $target"
        return
    fi
    if [ -e "$target" ] || [ -L "$target" ]; then
        backup_item "$target"
    fi

    ln -s "$source" "$target"
    log_success "リンク作成: $target -> $source"
}

link_dotfiles() {
    log_info "dotfiles のシンボリックリンクを作成中... ($DOTFILES_DIR)"

    # zsh
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/zsh/.zshenv" "$HOME/.zshenv"
    create_symlink "$DOTFILES_DIR/zsh/.zsh_aliases" "$HOME/.zsh_aliases"

    # bash (エイリアスは zsh と共通)
    create_symlink "$DOTFILES_DIR/bash/.bashrc" "$HOME/.bashrc"
    create_symlink "$DOTFILES_DIR/bash/.bash_profile" "$HOME/.bash_profile"
    create_symlink "$DOTFILES_DIR/zsh/.zsh_aliases" "$HOME/.bash_aliases"

    # Starship
    create_symlink "$DOTFILES_DIR/starship/starship.toml" "$HOME/.config/starship.toml"

    # Sheldon
    create_symlink "$DOTFILES_DIR/sheldon/plugins.toml" "$HOME/.config/sheldon/plugins.toml"

    # mise
    create_symlink "$DOTFILES_DIR/mise/config.toml" "$HOME/.config/mise/config.toml"

    # Yazi
    create_symlink "$DOTFILES_DIR/yazi" "$HOME/.config/yazi"

    # Neovim (LazyVim)
    create_symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
}

# ------------------------------
# Yazi のプラグイン
# ------------------------------
install_yazi_plugins() {
    if ! "$MISE" which ya >/dev/null 2>&1; then
        log_warn "ya が見つからないため Yazi のプラグインのインストールを省略します"
        return
    fi
    log_info "ya pkg install を実行します..."
    "$MISE" exec -- ya pkg install
}

# ------------------------------
# Rust (rustup)
# ------------------------------
# Rust は mise ではなく rustup で管理する (プロジェクトごとのバージョンは rust-toolchain.toml で指定する)
# PATH は .zshenv / .bashrc で設定するため --no-modify-path を付ける
# インストール後の更新は rustup update を実行する
install_rust() {
    local rustup="$HOME/.cargo/bin/rustup"
    if [ -x "$rustup" ]; then
        log_success "rustup はインストール済みです (更新は rustup update)"
    else
        log_info "rustup と Rust (stable) をインストール中..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs |
            sh -s -- -y --no-modify-path --default-toolchain stable --profile default
        log_success "Rust をインストールしました"
    fi
    # Neovim (LazyVim の rust extra) が使う rust-analyzer は、ツールチェーンとバージョンを揃えるため rustup で入れる
    if ! "$rustup" component add rust-analyzer; then
        log_warn "rust-analyzer のインストールに失敗しました (rustup default stable を実行してから再実行してください)"
    fi
}

# ------------------------------
# vcpkg (C++ のパッケージマネージャー)
# ------------------------------
# ~/.local/share/vcpkg に clone する (VCPKG_ROOT と PATH は .zshenv / .bashrc で設定)
# インストール後の更新は git -C ~/.local/share/vcpkg pull && ~/.local/share/vcpkg/bootstrap-vcpkg.sh -disableMetrics
install_vcpkg() {
    local dest="$HOME/.local/share/vcpkg"
    if [ -x "$dest/vcpkg" ]; then
        log_success "vcpkg はインストール済みです"
        return
    fi
    log_info "vcpkg をインストール中..."
    if [ ! -d "$dest/.git" ]; then
        git clone https://github.com/microsoft/vcpkg.git "$dest"
    fi
    "$dest/bootstrap-vcpkg.sh" -disableMetrics
    log_success "vcpkg をインストールしました"
}

# ------------------------------
# ble.sh (bash の補完・サジェスト・シンタックスハイライト)
# ------------------------------
# インストール後の更新は bash 上で ble-update を実行する
install_blesh() {
    local dest="$HOME/.local/share/blesh/ble.sh"
    if [ -f "$dest" ]; then
        log_success "ble.sh はインストール済みです (更新は bash で ble-update)"
        return
    fi
    log_info "ble.sh をインストール中..."
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/akinomyoga/ble.sh/releases/download/nightly/ble-nightly.tar.xz | tar xJf - -C "$tmp"
    bash "$tmp/ble-nightly/ble.sh" --install "$HOME/.local/share"
    rm -rf "$tmp"
    log_success "ble.sh をインストールしました"
}

# ------------------------------
# win32yank (WSL のみ)
# ------------------------------
# .zshenv で Windows 側の PATH を除外しているため、Neovim がクリップボード連携に使えるよう ~/.local/bin に配置する
install_win32yank() {
    if ! is_wsl; then
        return
    fi
    local dest="$HOME/.local/bin/win32yank.exe"
    if [ -x "$dest" ]; then
        log_success "win32yank はインストール済みです"
        return
    fi
    log_info "win32yank をインストール中..."
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "$tmp/win32yank.zip" https://github.com/equalsraf/win32yank/releases/download/v0.1.1/win32yank-x64.zip
    unzip -o -q "$tmp/win32yank.zip" win32yank.exe -d "$tmp"
    install -D -m 0755 "$tmp/win32yank.exe" "$dest"
    rm -rf "$tmp"
    log_success "win32yank をインストールしました"
}

# ------------------------------
# Docker
# ------------------------------
install_docker() {
    if dpkg -s docker-ce >/dev/null 2>&1; then
        log_success "Docker はインストール済みです (apt upgrade で更新済み)"
    else
        log_info "Docker をインストール中..."

        # 競合する古いパッケージを削除 (インストールされているものだけ)
        local pkg old_pkgs=()
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
            if dpkg -s "$pkg" >/dev/null 2>&1; then
                old_pkgs+=("$pkg")
            fi
        done
        if [ "${#old_pkgs[@]}" -gt 0 ]; then
            log_warn "競合するパッケージを削除: ${old_pkgs[*]}"
            sudo apt-get remove -y "${old_pkgs[@]}"
        fi

        # Docker の公式 GPG キーを追加
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc

        # Docker リポジトリを追加
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        log_success "Docker をインストールしました"
    fi

    # Docker グループに現在のユーザーを追加
    getent group docker >/dev/null || sudo groupadd docker
    if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
        log_success "$USER は docker グループに所属しています"
    else
        log_info "docker グループに $USER を追加中..."
        sudo usermod -aG docker "$USER"
        log_success "docker グループに $USER を追加しました (再ログイン後に反映)"
    fi

    # Docker サービスを有効化して起動 (systemd が無い WSL では省略)
    if [ -d /run/systemd/system ]; then
        sudo systemctl enable --now docker
    else
        log_warn "systemd が動いていないため Docker サービスの自動起動を省略します (WSL は /etc/wsl.conf で systemd=true を設定してください)"
    fi
}

cleanup_apt() {
    sudo apt-get autoremove -y
    sudo apt-get autoclean -y
}

# ------------------------------
# メイン処理
# ------------------------------
# dotfiles 内で実行すると mise が mise/config.toml をローカル設定として読み込み、trust を求めるため移動する
cd "$HOME"

if [ "$SKIP_APT" = true ]; then
    log_warn "apt と Docker のインストールを省略します"
else
    install_apt_packages
fi
set_default_shell
install_mise
link_dotfiles
install_mise_tools
install_yazi_plugins
install_rust
install_vcpkg
install_blesh
install_win32yank
if [ "$SKIP_APT" = false ]; then
    install_docker
    cleanup_apt
fi

log_success "セットアップが完了しました！"
log_warn "デフォルトシェルや docker グループの変更は、ログアウトして再度ログインすると反映されます。"

echo ""
echo -e "${GREEN}インストールされたツールのバージョン:${NC}"
echo "zsh: $(zsh --version 2>/dev/null || echo '未インストール')"
echo "mise: $("$MISE" --version)"
"$MISE" ls --current
if [ -x "$HOME/.cargo/bin/rustc" ]; then
    echo "rust: $("$HOME/.cargo/bin/rustc" --version)"
fi
echo "g++: $(g++ --version 2>/dev/null | head -n 1 || echo '未インストール')"
echo "clang++: $(clang++ --version 2>/dev/null | head -n 1 || echo '未インストール')"
if command -v docker >/dev/null 2>&1; then
    echo "docker: $(docker --version)"
fi
