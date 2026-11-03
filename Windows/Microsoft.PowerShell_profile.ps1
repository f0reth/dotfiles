# ------------------------------
# 環境変数
# ------------------------------
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'

# Starship の設定 (このファイルの場所から dotfiles の Windows 用の starship.windows.toml を指す)
$env:STARSHIP_CONFIG = Join-Path (Split-Path -Parent $PSScriptRoot) 'starship\starship.windows.toml'

# Git for Windows (winget 版 / Scoop 版のどちらか)
$gitRoot = @(
    "$env:ProgramFiles\Git"
    "$HOME\scoop\apps\git\current"
) | Where-Object { Test-Path "$_\usr\bin\file.exe" } | Select-Object -First 1

if ($gitRoot) {
    # Yazi がファイル種別の判定に使う file.exe
    $env:YAZI_FILE_ONE = "$gitRoot\usr\bin\file.exe"
    # Yazi の piper プラグインが sh を使うため、Git の bin (bash / sh / git のみ) を末尾に追加する
    if ($env:PATH -notlike "*$gitRoot\bin*") {
        $env:PATH += ";$gitRoot\bin"
    }
}
Remove-Variable gitRoot

# CMake: 既定のジェネレーターを Ninja にし、clangd 用の compile_commands.json を常に出力する
# (MSVC でビルドするときは、先に vsdev で開発者シェルを有効にする)
$env:CMAKE_GENERATOR = 'Ninja'
$env:CMAKE_EXPORT_COMPILE_COMMANDS = 'ON'

# ------------------------------
# mise
# ------------------------------
# mise で入れたツール (node, bun, uv など) を以降で使うため最初に読み込む
if (Get-Command mise -ErrorAction SilentlyContinue) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}

# ------------------------------
# エイリアス
# ------------------------------
# 組み込みエイリアスは関数より優先されるため、先に削除する
Remove-Item Alias:ls -Force -ErrorAction SilentlyContinue

# eza
function ls { eza --icons=auto @args }
function ll { eza -l --icons=auto @args }
function la { eza -a --icons=auto @args }

# Neovim
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value nvim

# ripgrep
Set-Alias -Name grep -Value rg

# ------------------------------
# 関数
# ------------------------------
# eza でツリー表示（第1引数が数字なら階層の深さとして扱う）
function lt {
    if ($args.Count -gt 0 -and "$($args[0])" -match '^\d+$') {
        eza --tree --level $args[0] @($args | Select-Object -Skip 1)
    }
    else {
        eza --tree @args
    }
}

# Yazi (終了時のディレクトリに移動する。y で起動)
function y {
    $tmp = (New-TemporaryFile).FullName
    yazi @args --cwd-file="$tmp"
    $cwd = Get-Content -LiteralPath $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }
    Remove-Item -LiteralPath $tmp
}

# MSVC の開発者シェル (cl / link / Windows SDK の PATH や INCLUDE) を現在のセッションで有効にする
# プロファイルで毎回読み込むと起動が遅くなるため、MSVC でビルドするときだけ実行する
function vsdev {
    $installerDir = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer'
    $vswhere = Join-Path $installerDir 'vswhere.exe'
    $vsPath = if (Test-Path -LiteralPath $vswhere) {
        & $vswhere -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -latest -property installationPath
    }
    if (-not $vsPath) {
        Write-Error 'MSVC Build Tools が見つかりません (Windows\installer.ps1 でインストールしてください)'
        return
    }
    # 開発者シェルの初期化スクリプト (VsDevCmd.bat) が PATH から vswhere.exe を探すため追加する
    # (Build Tools だけを入れた環境では Installer のフォルダーが PATH に入らない)
    if ($env:PATH -notlike "*$installerDir*") {
        $env:PATH += ";$installerDir"
    }
    Import-Module (Join-Path $vsPath 'Common7\Tools\Microsoft.VisualStudio.DevShell.dll')
    # -SkipAutomaticLocation: 開発者シェルが %USERPROFILE%\source\repos に移動しないようにする
    Enter-VsDevShell -VsInstallPath $vsPath -SkipAutomaticLocation -DevCmdArguments '-arch=x64 -host_arch=x64'
}

# Unix 風コマンド
# ファイル名が -n に割り当てられないよう、Path を先に宣言する
function touch {
    param([Parameter(Mandatory, ValueFromRemainingArguments)][string[]]$Path)
    foreach ($p in $Path) {
        if (Test-Path -LiteralPath $p) {
            (Get-Item -LiteralPath $p).LastWriteTime = Get-Date
        }
        else {
            New-Item -ItemType File -Path $p | Out-Null
        }
    }
}

function which {
    param([Parameter(Mandatory)][string]$Name)
    Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

# ------------------------------
# ツール初期化
# ------------------------------
# Starship
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (& starship init powershell)
}
