#Requires -Version 5.1

<#
.SYNOPSIS
    Windows開発ツール自動インストールスクリプト (winget版)
.DESCRIPTION
    wingetを使用してYazi, Neovim, Ripgrep (MSVC), Ezaを自動的にインストールします
.NOTES
    Windows 10 version 1909以降またはWindows 11が必要です
#>

param(
    [switch]$Force,
    [switch]$Verbose,
    [switch]$AcceptAll
)

# ログ関数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# wingetの利用可能性チェック
function Test-Winget {
    try {
        $wingetVersion = & winget --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Log "winget version: $wingetVersion" "SUCCESS"
            return $true
        }
    }
    catch {
        Write-Log "winget command not found" "ERROR"
    }
    return $false
}

# wingetのインストール
function Install-Winget {
    Write-Log "winget is not available. Attempting to install..." "WARN"
    
    try {
        # App Installer (winget) のダウンロードとインストール
        Write-Log "Downloading Microsoft App Installer..."
        $appInstallerUrl = "https://aka.ms/getwinget"
        $tempFile = Join-Path $env:TEMP "Microsoft.DesktopAppInstaller.msixbundle"
        
        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $tempFile -UseBasicParsing
        
        Write-Log "Installing Microsoft App Installer..."
        Add-AppxPackage -Path $tempFile
        
        # インストール後の確認
        Start-Sleep -Seconds 5
        if (Test-Winget) {
            Write-Log "winget installed successfully" "SUCCESS"
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            return $true
        } else {
            throw "winget installation verification failed"
        }
    }
    catch {
        Write-Log "Failed to install winget: $($_.Exception.Message)" "ERROR"
        Write-Log "Please install 'App Installer' from Microsoft Store manually" "ERROR"
        return $false
    }
}

# ツールのインストール状況確認
function Test-Tool {
    param([string]$Command)
    
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# wingetでツールをインストール
function Install-WithWinget {
    param(
        [string]$PackageId,
        [string]$PackageName,
        [string]$Command
    )
    
    # 既にインストール済みかチェック
    if ((Test-Tool $Command) -and -not $Force) {
        Write-Log "$PackageName is already installed (use -Force to reinstall)" "SUCCESS"
        return $true
    }
    
    try {
        Write-Log "Installing $PackageName ($PackageId)..."
        
        # wingetコマンドの構築
        $arguments = @("install", "--id=$PackageId")
        
        if ($AcceptAll) {
            $arguments += "--accept-package-agreements"
            $arguments += "--accept-source-agreements"
        }
        
        if ($Force) {
            $arguments += "--force"
        }
        
        # サイレントインストール（可能な場合）
        $arguments += "--silent"
        
        if ($Verbose) {
            Write-Log "Running: winget $($arguments -join ' ')" "INFO"
        }
        
        # wingetの実行
        $process = Start-Process "winget" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "$PackageName installed successfully" "SUCCESS"
            return $true
        } elseif ($process.ExitCode -eq -1978335189) {
            # パッケージが既にインストールされている場合
            Write-Log "$PackageName is already installed" "SUCCESS"
            return $true
        } else {
            throw "winget installation failed with exit code $($process.ExitCode)"
        }
    }
    catch {
        Write-Log "Failed to install $PackageName: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# パッケージの検索と確認
function Search-WingetPackage {
    param([string]$PackageId)
    
    try {
        $result = & winget search --id $PackageId --exact 2>$null
        return ($LASTEXITCODE -eq 0)
    }
    catch {
        return $false
    }
}

# パスの更新
function Update-Path {
    $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
    Write-Log "Environment PATH updated" "INFO"
}

# メイン処理
function Main {
    Write-Log "=== Windows Development Tools Installer (winget) ===" "SUCCESS"
    Write-Log "Installing: Yazi, Neovim, Ripgrep (MSVC), Eza"
    
    # wingetの確認とインストール
    if (-not (Test-Winget)) {
        if (-not (Install-Winget)) {
            Write-Log "Cannot proceed without winget. Exiting." "ERROR"
            return $false
        }
    }
    
    # wingetソースの更新
    Write-Log "Updating winget sources..."
    try {
        & winget source update 2>$null
        Write-Log "winget sources updated" "SUCCESS"
    }
    catch {
        Write-Log "Failed to update winget sources, continuing anyway..." "WARN"
    }
    
    $success = $true
    $installationResults = @{}
    
    # インストールするパッケージの定義
    $packages = @(
        @{
            Id = "sxyazi.yazi"
            Name = "Yazi"
            Command = "yazi"
            Description = "Modern file manager"
        },
        @{
            Id = "Neovim.Neovim"
            Name = "Neovim"
            Command = "nvim"
            Description = "Hyperextensible Vim-based text editor"
        },
        @{
            Id = "BurntSushi.ripgrep.MSVC"
            Name = "Ripgrep (MSVC)"
            Command = "rg"
            Description = "Fast search tool"
        },
        @{
            Id = "eza-community.eza"
            Name = "Eza"
            Command = "eza"
            Description = "Modern replacement for ls"
        },
	@   Id = "sharkdp.bat"
	    Name = "BAT"
	    Command = "bat"
	    Description = "catのすごい版"
	}
    )
    
    # 各パッケージのインストール
    Write-Log "Starting package installations..." "INFO"
    
    foreach ($package in $packages) {
        Write-Log "Processing $($package.Name) - $($package.Description)" "INFO"
        
        # パッケージの存在確認
        if (-not (Search-WingetPackage $package.Id)) {
            Write-Log "Package $($package.Id) not found in winget" "WARN"
            $installationResults[$package.Name] = $false
            continue
        }
        
        # インストール実行
        $installationResults[$package.Name] = Install-WithWinget $package.Id $package.Name $package.Command
        
        if (-not $installationResults[$package.Name]) {
            $success = $false
        }
        
        # インストール間隔
        Start-Sleep -Seconds 2
    }
    
    # パス更新
    Update-Path
    
    # 結果の表示
    Write-Log "=== Installation Results ===" "SUCCESS"
    foreach ($package in $packages) {
        $packageName = $package.Name
        $status = if ($installationResults[$packageName]) { "SUCCESS" } else { "FAILED" }
        $level = if ($installationResults[$packageName]) { "SUCCESS" } else { "ERROR" }
        Write-Log "$packageName : $status" $level
    }
    
    # 最終確認
    Write-Log "=== Final Verification ===" "INFO"
    Start-Sleep -Seconds 3  # パス更新の時間を待つ
    
    foreach ($package in $packages) {
        $command = $package.Command
        $name = $package.Name
        
        if (Test-Tool $command) {
            try {
                $version = & $command --version 2>$null | Select-Object -First 1
                Write-Log "$name is ready: $version" "SUCCESS"
            }
            catch {
                Write-Log "$name is available" "SUCCESS"
            }
        } else {
            Write-Log "$name is not available in PATH. Try restarting your terminal." "WARN"
        }
    }
    
    if ($success) {
        Write-Log "All tools installed successfully!" "SUCCESS"
        Write-Log "Please restart your PowerShell session to ensure all tools are available in PATH." "SUCCESS"
    } else {
        Write-Log "Some installations failed. Check the logs above for details." "ERROR"
        Write-Log "You can try running the script again or install failed packages manually." "INFO"
    }
    
    # 使用方法のヒント
    Write-Log "=== Quick Start Tips ===" "INFO"
    Write-Log "• Yazi file manager: yazi" "INFO"
    Write-Log "• Neovim editor: nvim filename" "INFO"
    Write-Log "• Search files: rg 'pattern'" "INFO"
    Write-Log "• List files: eza -la" "INFO"
    
    return $success
}

# スクリプト実行
try {
    # Windows バージョンチェック
    $windowsVersion = [System.Environment]::OSVersion.Version
    if ($windowsVersion.Major -lt 10 -or ($windowsVersion.Major -eq 10 -and $windowsVersion.Build -lt 17763)) {
        Write-Log "This script requires Windows 10 version 1809 or later" "ERROR"
        exit 1
    }
    
    $result = Main
    exit $(if ($result) { 0 } else { 1 })
}
catch {
    Write-Log "Script execution failed: $($_.Exception.Message)" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}