#Requires -Version 5.1

<#
.SYNOPSIS
    Windows 開発環境セットアップスクリプト (winget + Scoop + mise)
.DESCRIPTION
    1. winget.json のアプリをインストールし、インストール済みのものは最新版にアップグレード
       (Version を指定したものはそのバージョンに固定)
    2. Scoop が無ければインストール
    3. scoopfile.json のバケット/アプリを scoop import でインストール
    4. 設定を適用する
       - mise / Yazi / Neovim: 設定ディレクトリをジャンクションでリンク
       - VS Code: settings.json / keybindings.json をシンボリックリンクでリンク
       - mpv: ユーザー環境変数 MPV_HOME を設定
       - PowerShell: プロファイルから dotfiles のプロファイルを読み込む
         (Starship の設定は dotfiles のプロファイルで STARSHIP_CONFIG を設定)
    5. mise install で言語ランタイムを、ya pkg install で Yazi のプラグインをインストール
.PARAMETER SkipWinget
    winget でのインストールを省略する (アプリが揃っていて時間を短縮したいとき)
.NOTES
    GUIアプリは winget、CLIツールは Scoop、言語ランタイムは mise で管理します。
    ディレクトリはジャンクションでリンクするため、開発者モードや管理者権限は不要です。
    ただし VS Code の設定ファイルはシンボリックリンクのため、開発者モードを有効にしておく必要があります
    (無効の場合は VS Code のリンクだけ省略します)。
#>

param(
    [switch]$SkipWinget
)

$ErrorActionPreference = 'Stop'

$DotfilesDir = Split-Path -Parent $PSScriptRoot
$WingetFile = Join-Path $PSScriptRoot 'winget.json'
$ScoopFile = Join-Path $PSScriptRoot 'scoopfile.json'
$MiseConfigSource = Join-Path $DotfilesDir 'mise'
$MiseConfigTarget = Join-Path $HOME '.config\mise'
# Windows 版 Yazi の設定ディレクトリは %APPDATA%\yazi\config
$YaziConfigSource = Join-Path $DotfilesDir 'yazi'
$YaziConfigTarget = Join-Path $env:APPDATA 'yazi\config'
# Windows 版 Neovim の設定ディレクトリは %LOCALAPPDATA%\nvim
$NvimConfigSource = Join-Path $DotfilesDir 'nvim'
$NvimConfigTarget = Join-Path $env:LOCALAPPDATA 'nvim'
# VS Code のユーザー設定は %APPDATA%\Code\User
# (フォルダには履歴や拡張機能の状態もあるため、管理する 2 ファイルだけをシンボリックリンクにする)
$VSCodeConfigSource = Join-Path $DotfilesDir 'vscode'
$VSCodeConfigTarget = Join-Path $env:APPDATA 'Code\User'
$VSCodeConfigFiles = @('settings.json', 'keybindings.json')
# Scoop 版 mpv は本体横の portable_config を読むため、MPV_HOME で dotfiles を優先させる
# (エクスプローラーから起動しても効くよう、プロファイルではなくユーザー環境変数に設定する)
$MpvConfigSource = Join-Path $DotfilesDir 'mpv'
$ProfileSource = Join-Path $PSScriptRoot 'Microsoft.PowerShell_profile.ps1'
# Windows PowerShell 5.1 から実行しても PowerShell 7 のプロファイルを対象にする
$ProfileTarget = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell\Microsoft.PowerShell_profile.ps1'

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $color = switch ($Level) {
        'ERROR'   { 'Red' }
        'WARN'    { 'Yellow' }
        'SUCCESS' { 'Green' }
        default   { 'Cyan' }
    }
    Write-Host "[$Level] $Message" -ForegroundColor $color
}

function Test-Command {
    param([string]$Name)
    [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Update-SessionPath {
    $env:PATH = @(
        [Environment]::GetEnvironmentVariable('PATH', 'User')
        [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    ) -join ';'
}

# winget の終了コード
$WingetUpdateNotApplicable = -1978335189  # 0x8A15002B: 利用可能なアップグレードが無い
$WingetNoInstalledPackage = -1978335212   # 0x8A150014: インストールされていない

# winget.json のパッケージを { Id, Version, Source } の一覧にする
function Get-WingetPackages {
    foreach ($source in (Get-Content -LiteralPath $WingetFile -Raw | ConvertFrom-Json).Sources) {
        foreach ($pkg in $source.Packages) {
            [pscustomobject]@{
                Id      = $pkg.PackageIdentifier
                Version = $pkg.Version
                Source  = $source.SourceDetails.Name
            }
        }
    }
}

function Import-WingetApps {
    if (-not (Test-Command 'winget')) {
        throw 'winget が見つかりません。Microsoft Store から「アプリ インストーラー」をインストールしてください'
    }

    # 1. 未インストールのものだけ入れる (Version 指定のものはそのバージョンで入る)
    #    アップグレードは 3. で行い、Version 指定のものが上がらないようにする
    Write-Log "winget import $WingetFile"
    winget import --import-file $WingetFile --no-upgrade --ignore-unavailable `
        --accept-package-agreements --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        # 一部の失敗で後続 (Scoop / mise) を止めない
        Write-Log "一部のパッケージのインストールに失敗しました (exit code: $LASTEXITCODE)。上のログを確認してください" 'WARN'
    }

    # 2. Version 指定のものをピン留め
    Add-WingetPins

    # 3. Version 指定の無いものを最新版にアップグレード
    Update-WingetApps

    # 4. PowerShell 7 は MSI 版で入れる / アップグレードする
    Install-PowerShellMsi

    Update-SessionPath
}

# winget.json で Version を指定したパッケージを、そのバージョンにピン留めする
# (手動の winget upgrade --all でも上がらないようにする)
function Add-WingetPins {
    foreach ($pkg in Get-WingetPackages | Where-Object { $_.Version }) {
        Write-Log "ピン留め: $($pkg.Id) $($pkg.Version)"
        # --force: 既存のピンがあれば上書きする
        winget pin add --id $pkg.Id --exact --source $pkg.Source --version $pkg.Version --force `
            --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            Write-Log "$($pkg.Id) のピン留めに失敗しました (exit code: $LASTEXITCODE)" 'WARN'
        }
    }
}

# winget.json のうち Version 指定の無いパッケージだけを最新版にする
# (winget upgrade --all だと winget.json に無いランタイム等まで上がるため 1 つずつ実行する)
# PowerShell 7 を MSI 版でインストール / アップグレードする
# - winget の既定は MSIX 版で、パッケージ化されたアプリとして動くため
#   ファイル・レジストリへの書き込みが仮想化されるなど、Claude Code などのツールが正常に動かない
# - MSI 版は winget の --id 指定では「インストールされていない」と判定され winget upgrade が使えないため、
#   pwsh.exe のバージョンと winget の最新版を比べ、古ければ MSI を上書きインストールする
#   (MSI 版は上書きインストールでアップグレードされる)
# - winget.json の一括インストールに含めると MSIX 版が入るため、winget.json には書かない
function Install-PowerShellMsi {
    $id = 'Microsoft.PowerShell'
    $pwshExe = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'

    if (Get-AppxPackage -Name 'Microsoft.PowerShell' -ErrorAction SilentlyContinue) {
        Write-Log 'MSIX 版の PowerShell が入っています。MSI 版と競合するため、削除を推奨します: Get-AppxPackage Microsoft.PowerShell | Remove-AppxPackage' 'WARN'
    }

    # winget の最新版 ("バージョン: 7.6.9.0" / "Version: 7.6.9.0" の行から取得)
    $latest = winget show --id $id --exact --source winget --installer-type wix --accept-source-agreements |
        Select-String -Pattern ':\s*(\d+\.\d+\.\d+)(\.\d+)?\s*$' |
        Select-Object -First 1 |
        ForEach-Object { [version]$_.Matches[0].Groups[1].Value }
    if (-not $latest) {
        Write-Log 'winget から PowerShell の最新バージョンを取得できませんでした' 'WARN'
        return
    }

    if (Test-Path -LiteralPath $pwshExe) {
        # ProductVersion は "7.6.9 SHA: ..." の形式
        $installed = [version](((Get-Item -LiteralPath $pwshExe).VersionInfo.ProductVersion -split ' ')[0])
        if ($installed -ge $latest) {
            Write-Log "PowerShell $installed (MSI 版) は最新です"
            return
        }
        Write-Log "PowerShell を $installed から $latest にアップグレードします (MSI 版)"
    }
    else {
        Write-Log "PowerShell $latest をインストールします (MSI 版)"
    }

    winget install --id $id --exact --source winget --installer-type wix --scope machine `
        --accept-package-agreements --accept-source-agreements | Out-Host
    if ($LASTEXITCODE -eq 0) {
        Write-Log "PowerShell $latest をインストールしました" 'SUCCESS'
    }
    else {
        Write-Log "PowerShell のインストールに失敗しました (exit code: $LASTEXITCODE)。PowerShell 7 から実行している場合は、Windows PowerShell から再実行してください" 'WARN'
    }
}

function Update-WingetApps {
    foreach ($pkg in Get-WingetPackages | Where-Object { -not $_.Version }) {
        Write-Log "アップグレード確認: $($pkg.Id)"
        winget upgrade --id $pkg.Id --exact --source $pkg.Source `
            --accept-package-agreements --accept-source-agreements | Out-Host
        switch ($LASTEXITCODE) {
            0 { Write-Log "$($pkg.Id) をアップグレードしました" 'SUCCESS' }
            $WingetUpdateNotApplicable { Write-Log "$($pkg.Id) は最新です" }
            $WingetNoInstalledPackage { Write-Log "$($pkg.Id) はインストールされていません (1. で失敗した可能性があります)" 'WARN' }
            default { Write-Log "$($pkg.Id) のアップグレードに失敗しました (exit code: $LASTEXITCODE)" 'WARN' }
        }
    }
}

function Install-Scoop {
    if (Test-Command 'scoop') {
        Write-Log 'Scoop はインストール済みです' 'SUCCESS'
        return
    }
    Write-Log 'Scoop をインストールします...'
    Invoke-RestMethod -Uri 'https://get.scoop.sh' | Invoke-Expression
    Update-SessionPath
    if (-not (Test-Command 'scoop')) {
        throw 'Scoop のインストールに失敗しました'
    }
    Write-Log 'Scoop をインストールしました' 'SUCCESS'
}

function Import-ScoopApps {
    # バケットの追加に git が必要
    if (-not (Test-Command 'git')) {
        Write-Log 'git が見つからないため Scoop でインストールします...'
        scoop install git
    }
    Write-Log "scoop import $ScoopFile"
    scoop import $ScoopFile
    Update-SessionPath
}

# 既存のファイル/ディレクトリを <パス>.bak_日時 に退避する
function Backup-Item {
    param([string]$Path)
    $backup = "$Path.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Move-Item -LiteralPath $Path -Destination $backup
    Write-Log "既存のファイルをバックアップ: $backup" 'WARN'
}

# ディレクトリをジャンクションでリンクする
# (シンボリックリンクと違い、開発者モードや管理者権限が不要)
function New-DirectoryJunction {
    param([string]$Source, [string]$Target)

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null

    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq 'Junction' -and @($existing.Target)[0] -eq $Source) {
            Write-Log "リンク済み: $Target" 'SUCCESS'
            return
        }
        Backup-Item $Target
    }

    New-Item -ItemType Junction -Path $Target -Target $Source | Out-Null
    Write-Log "リンク作成: $Target -> $Source" 'SUCCESS'
}

# ファイルをシンボリックリンクでリンクする
# (開発者モードが有効なら管理者権限なしで作成できる)
function New-FileSymlink {
    param([string]$Source, [string]$Target)

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
        Write-Log "ソースファイルが存在しません: $Source" 'WARN'
        return
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Target) | Out-Null

    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -eq 'SymbolicLink' -and @($existing.Target)[0] -eq $Source) {
            Write-Log "リンク済み: $Target" 'SUCCESS'
            return
        }
        Backup-Item $Target
    }

    if (-not (New-SymlinkWithMklink -Source $Source -Target $Target)) {
        throw "シンボリックリンクの作成に失敗しました: $Target"
    }
    Write-Log "リンク作成: $Target -> $Source" 'SUCCESS'
}

# mklink でファイルのシンボリックリンクを作る
# (Windows PowerShell 5.1 の New-Item は開発者モードでも管理者権限を求めるため mklink を使う)
function New-SymlinkWithMklink {
    param([string]$Source, [string]$Target)
    cmd /c mklink "$Target" "$Source" 2>&1 | Out-Null
    $LASTEXITCODE -eq 0
}

# シンボリックリンクを作成できるか (開発者モードが有効、または管理者として実行) を調べる
function Test-SymlinkAvailable {
    $dir = Join-Path ([IO.Path]::GetTempPath()) "symlink-test-$PID"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    try {
        $source = Join-Path $dir 'source'
        New-Item -ItemType File -Path $source | Out-Null
        New-SymlinkWithMklink -Source $source -Target (Join-Path $dir 'link')
    }
    finally {
        Remove-Item -LiteralPath $dir -Recurse -Force
    }
}

function Set-VSCodeConfig {
    if (-not (Test-SymlinkAvailable)) {
        Write-Log 'シンボリックリンクを作成できないため VS Code の設定のリンクを省略します (設定 → システム → 開発者向け で開発者モードを有効にしてください)' 'WARN'
        return
    }
    if (Get-Process -Name 'Code' -ErrorAction SilentlyContinue) {
        Write-Log 'VS Code が起動しています。設定が上書きされることがあるため、閉じてから再実行することを推奨します' 'WARN'
    }
    foreach ($file in $VSCodeConfigFiles) {
        New-FileSymlink -Source (Join-Path $VSCodeConfigSource $file) -Target (Join-Path $VSCodeConfigTarget $file)
    }
}

# PowerShell プロファイルは、dotfiles のプロファイルを読み込むだけのファイルにする
# (プロファイルのフォルダには他のファイルもあるためジャンクションにできない)
function Set-ProfileLoader {
    $loader = ". `"$ProfileSource`""
    $current = Get-Content -LiteralPath $ProfileTarget -Raw -ErrorAction SilentlyContinue
    if ($current -and $current.Trim() -eq $loader) {
        Write-Log "設定済み: $ProfileTarget" 'SUCCESS'
        return
    }
    if (Test-Path -LiteralPath $ProfileTarget) {
        Backup-Item $ProfileTarget
    }
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $ProfileTarget) | Out-Null
    Set-Content -LiteralPath $ProfileTarget -Value $loader -Encoding UTF8
    Write-Log "プロファイル作成: $ProfileTarget -> $ProfileSource を読み込み" 'SUCCESS'
}

# ユーザー環境変数を設定する (現在のセッションにも反映)
function Set-UserEnvironment {
    param([string]$Name, [string]$Value)
    if ([Environment]::GetEnvironmentVariable($Name, 'User') -eq $Value) {
        Write-Log "設定済み: $Name=$Value" 'SUCCESS'
    }
    else {
        [Environment]::SetEnvironmentVariable($Name, $Value, 'User')
        Write-Log "ユーザー環境変数を設定: $Name=$Value" 'SUCCESS'
    }
    Set-Item -Path "Env:$Name" -Value $Value
}

function Install-YaziPlugins {
    if (-not (Test-Command 'ya')) {
        Write-Log 'ya が見つからないため Yazi のプラグインのインストールを省略します' 'WARN'
        return
    }
    Write-Log 'ya pkg install を実行します...'
    ya pkg install
}

function Install-MiseTools {
    if (-not (Test-Command 'mise')) {
        throw 'mise が見つかりません (scoopfile.json に mise が含まれているか確認してください)'
    }
    Write-Log 'mise install を実行します...'
    mise install
    Write-Log 'mise のツールをインストールしました' 'SUCCESS'
}

if ($SkipWinget) {
    Write-Log 'winget のインストールを省略します' 'WARN'
}
else {
    Import-WingetApps
}
Install-Scoop
Import-ScoopApps
New-DirectoryJunction -Source $MiseConfigSource -Target $MiseConfigTarget
New-DirectoryJunction -Source $YaziConfigSource -Target $YaziConfigTarget
New-DirectoryJunction -Source $NvimConfigSource -Target $NvimConfigTarget
Set-VSCodeConfig
Set-UserEnvironment -Name 'MPV_HOME' -Value $MpvConfigSource
Set-ProfileLoader
Install-MiseTools
Install-YaziPlugins

Write-Log 'セットアップが完了しました。PowerShell を再起動してください。' 'SUCCESS'
