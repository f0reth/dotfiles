# 使い方

GUIアプリは winget、CLIツールは Scoop、言語ランタイム (node / bun / uv) は mise、Rust は rustup、
C / C++ のコンパイラー (MSVC) は `installer.ps1` で管理します。

- winget で入れるアプリ: `winget.json`
- Scoop で入れるアプリ: `scoopfile.json`
- mise で入れるツール: `../mise/config.toml` (`os = ["linux", "macos"]` のものは Windows では入らない)

## インストール

管理者ではない PowerShell で実行します (Scoop は管理者での実行を拒否します)。
設定のリンクには主にジャンクションを使うため、管理者権限は不要です。
ただし VS Code の設定ファイルはシンボリックリンクでリンクするため、
事前に開発者モードを有効にしてください (設定 → システム → 開発者向け → 開発者モード)。
無効のままだと VS Code のリンクだけ省略されます。

```powershell
.\installer.ps1

# winget を省略 (Scoop / mise だけ反映したいとき)
.\installer.ps1 -SkipWinget
```

実行内容:

1. `winget.json` のアプリをインストールし、インストール済みのものは最新版にアップグレード
   (`Version` を書いたものはそのバージョンに固定)
   - PowerShell 7 は `winget.json` に含めず、MSI 版を別にインストール / アップグレードします (下記)
2. Scoop が無ければインストール
3. `scoop import scoopfile.json` でアプリをインストール
4. 設定をリンク (既存のものは `.bak_日時` に退避)

   | dotfiles | リンク先 | 方法 |
   |---|---|---|
   | `mise/` | `~\.config\mise` | ジャンクション |
   | `yazi/` | `%APPDATA%\yazi\config` | ジャンクション |
   | `nvim/` | `%LOCALAPPDATA%\nvim` | ジャンクション |
   | `vscode/settings.json` | `%APPDATA%\Code\User\settings.json` | シンボリックリンク (開発者モードが必要。VS Code を閉じてから実行) |
   | `vscode/keybindings.json` | `%APPDATA%\Code\User\keybindings.json` | シンボリックリンク (同上) |
   | `mpv/` | - | ユーザー環境変数 `MPV_HOME` (Scoop 版の `portable_config` より優先される) |
   | `starship/starship.toml` | - | dotfiles のプロファイルで `STARSHIP_CONFIG` を設定 |
   | `Windows\Microsoft.PowerShell_profile.ps1` | `Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | dotfiles 側を読み込む 1 行だけのファイルを作成 |

5. `mise install` と `ya pkg install` (Yazi のプラグイン)
6. MSVC Build Tools と Rust をインストール (詳しくは下記の「C / C++ について」「Rust について」)
   - `-SkipWinget` を付けても実行します (インストール済みなら何もしません)

winget のアプリによっては UAC の確認が表示されます。

### PowerShell 7 について

winget で普通にインストールすると MSIX 版 (パッケージ化されたアプリ) が入ります。
MSIX 版はファイルやレジストリへの書き込みが仮想化されるなど制限があり、Claude Code などのツールが正常に動きません。
そのため `installer.ps1` では `--installer-type wix` で MSI 版 (`C:\Program Files\PowerShell\7`) をインストールします。

- MSI 版は winget の `--id` 指定では見つからず `winget upgrade` が使えないため、
  `pwsh.exe` のバージョンが winget の最新版より古いときに MSI を上書きインストールしてアップグレードします。
- 実行中の PowerShell 7 はアップグレードできないことがあるため、PowerShell 7 のアップグレード時は
  **Windows PowerShell (`powershell.exe`) から** `installer.ps1` を実行してください。
- MSIX 版が入っている場合は警告が表示されます。`Get-AppxPackage Microsoft.PowerShell | Remove-AppxPackage` で削除してください。
- 手動でインストールする場合:

  ```powershell
  winget install --id Microsoft.PowerShell --exact --source winget --installer-type wix --scope machine
  ```

### Rust について

Rust は mise ではなく rustup で管理します。
mise で `rust` を指定すると環境変数 `RUSTUP_TOOLCHAIN` が設定され、
プロジェクトの `rust-toolchain.toml` より優先されてしまうためです。

- **MSVC Build Tools**: Rust の既定のツールチェーン (`x86_64-pc-windows-msvc`) のリンカーとして必要です
  (C++ と共通。下記の「C / C++ について」を参照)。
- **rustup**: `rustup-init.exe` を公式サイトからダウンロードして stable を入れ、
  Neovim 用に `rust-analyzer` コンポーネントを追加します。
  winget の `Rustlang.Rustup` は、winget と rustup 自身の更新で二重管理になるため使いません。
  `~\.cargo\bin` はインストーラーがユーザー環境変数 PATH に追加します。
- MSVC Build Tools が見つからない場合、Rust のインストールは省略されます
  (`rustup-init -y` が Visual Studio Community のインストールを始めてしまうため)。
- WSL 側の Rust は `install.sh` で別にインストールします。

```powershell
# 更新 (ツールチェーンと rustup 本体)
rustup update

# プロジェクトでバージョンを固定する場合は、リポジトリに rust-toolchain.toml を置く
# [toolchain]
# channel = "1.91.0"
# components = ["clippy", "rustfmt"]
```

`~\.cargo\credentials.toml` (crates.io のトークン) は dotfiles に含めないでください。

### C / C++ について

MSVC を標準のコンパイラーにし、エディタ支援には LLVM (clangd) を使います。

| ツール | 入れ方 | 用途 |
|---|---|---|
| MSVC Build Tools | `installer.ps1` (winget + `--override`) | コンパイラー (`cl`)・リンカー・Windows SDK |
| CMake / Ninja | Scoop | ビルド |
| LLVM | Scoop | clangd / clang-format / clang-tidy / clang-cl |
| vcpkg | Scoop | ライブラリ管理 (`VCPKG_ROOT` は Scoop が設定) |
| gcc / gdb (MinGW, `mingw`) | Scoop | 単一ファイルを手早くコンパイルしたいとき用・Neovim の Treesitter パーサーのビルド |

- **MSVC Build Tools**: `winget.json` ではインストーラーに引数を渡せず C++ のワークロードが入らないため、
  `installer.ps1` が `--override` でワークロード (VCTools + Windows SDK) を指定してインストールします。
  更新は Visual Studio Installer から行います。
- **開発者シェル**: `cl` などは PATH に入らないため、MSVC でビルドするときは
  PowerShell で `vsdev` を実行してから `cmake` を使います (プロファイルで定義)。
- **CMake の既定値**: プロファイルで `CMAKE_GENERATOR=Ninja` と `CMAKE_EXPORT_COMPILE_COMMANDS=ON` を設定しています。
  `build/compile_commands.json` が出力され、clangd がそれを読んで補完・診断します。
- **エディタ**: Neovim は LazyVim の `lang.clangd` / `lang.cmake` extra、
  VS Code は clangd 拡張機能 (`llvm-vs-code-extensions.vscode-clangd`) を使います。
  どちらも clangd は Mason / 拡張機能に入れさせず、Scoop の LLVM のものを使います。
  VS Code でデバッグする場合は C/C++ 拡張機能 (`ms-vscode.cpptools`) を入れます (IntelliSense は設定で無効化済み)。
- **MinGW は Scoop の `mingw` (MinGW-Builds 版) を使う**。ほかの MinGW のパッケージは次の理由で使わない:
  - `gcc` (nuwen 版): ユーザー環境変数 `C_INCLUDE_PATH` / `CPLUS_INCLUDE_PATH` に自分の include フォルダーを設定する。
    clang / clangd はこれを読むため、MSVC のプロジェクトの解析に MinGW のヘッダー (同梱の Boost など) が混ざる
  - `mingw-winlibs`: cmake / ninja が同梱されていて、PATH の先頭に入るため Scoop の cmake / ninja より優先される
- g++ で `std::print` / `std::println` を使うときは `-lstdc++exp` を付けてリンクします (libstdc++ の Windows 版の仕様)。
- WSL 側は `install.sh` で gcc / clang / clangd / gdb (apt)、CMake / Ninja (mise)、vcpkg (git clone) を入れます。

```powershell
# vcpkg を使うプロジェクトの例 (vcpkg.json に依存ライブラリを書く manifest モード)
vsdev
vcpkg new --application
vcpkg add port fmt
cmake -B build -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
cmake --build build
```

## アプリ一覧の更新

- winget: アプリを追加・削除したら `winget.json` の `PackageIdentifier` を編集します。
  ID は `winget search <名前>` で調べられます。
  (`winget export` は Windows 標準アプリやランタイムまで含むため、出力をそのまま使わない)
  - 通常は最新版がインストールされ、インストール済みのものも最新版にアップグレードされます。
    (`winget.json` に無いアプリやランタイムはアップグレードしません)
  - `"Version": "x.y.z"` を書いたパッケージ (現在は ueli) はそのバージョンでインストールされ、
    `winget pin` でピン留めされます (`winget upgrade --all` で上がらない)。
    固定を解除するときは `Version` を消して `winget pin remove --id <ID>` を実行します。
- Scoop: アプリを追加・削除したら `scoopfile.json` にも反映します。
  `scoop export` の出力は Version や Updated を含むため、Name と Source だけを書き写します。

## 実行ポリシー設定

```powershell
# 一時的に実行を許可
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# または恒久的に設定
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## トラブルシューティング

- 実行ポリシーエラ

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

## PowerShell プロファイル

`Microsoft.PowerShell_profile.ps1` は PowerShell 7 のプロファイル
(`Documents\PowerShell\Microsoft.PowerShell_profile.ps1`) から読み込まれます。
zsh の設定 (`zsh/`) と同じコマンドが使えるように揃えています。

| コマンド | 内容 |
|---|---|
| `ls` / `ll` / `la` | eza |
| `lt [深さ]` | eza でツリー表示 |
| `y [ディレクトリ]` | Yazi を起動し、終了時のディレクトリに移動 |
| `vi` / `vim` | nvim |
| `grep` | rg |
| `touch` / `which` | Unix 風コマンド |
