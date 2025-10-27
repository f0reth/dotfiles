# =================================
# 環境変数設定
# =================================
$env:EDITOR = "nvim"
$env:VISUAL = "nvim"
$env:YAZI_FILE_ONE = "C:\Program Files\Git\usr\bin\file.exe"
$env:EZA_CONFIG_DIR = "C:\Users\daich\OneDrive\ドキュメント\PowerShell\config\eza"

# =================================
# 関数設定
# =================================
# ディレクトリ操作
function l {
    eza @args
}

function ll {
    eza -aahl --git @args
}

function la {
    eza -aa @args
}

function lt {
    eza --tree --level=3 @args
}

# ファイル操作
function cp { Copy-Item @args }
function mv { Move-Item @args }
function rm { Remove-Item @args }
function mkdir { New-Item -ItemType Directory @args }
function head { param([int]$n = 10) Get-Content @args | Select-Object -First $n }
function tail { param([int]$n = 10) Get-Content @args | Select-Object -Last $n }
#function touch { New-Item -ItemType File @args }
function touch {
    param([string[]]$Files)
    foreach ($file in $Files) {
        if (Test-Path $file) {
            (Get-Item $file).LastWriteTime = Get-Date
        } else {
            New-Item -ItemType File -Path $file -Force | Out-Null
        }
    }
}

# which コマンド
function which {
    param([string]$Command)
    Get-Command $Command -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
}

# pwd は既にPowerShellに存在するが、より詳細な版
function pwd { Get-Location }

# =================================
# エイリアス設定
# =================================
Set-Alias -Name vi -Value nvim
Set-Alias -Name vim -Value nvim
Set-Alias -Name grep -Value Select-String

# =================================
# プロンプト読み込み
# Yazi wrapper script loader
# =================================
try {
	# スクリプトファイルのパスを設定（必要に応じて変更してください）
	$yaziScriptPath = Join-Path $PSScriptRoot "Scripts/yazi-wrapper.ps1"

	# ファイルの存在確認
	if (Test-Path $yaziScriptPath) {
		# スクリプトを読み込み
		. $yaziScriptPath
		Write-Host "✓ Yazi wrapper loaded successfully" -ForegroundColor Green
	} else {
		Write-Warning "Yazi wrapper script not found at: $yaziScriptPath"
		Write-Host "Please ensure 'yazi-wrapper.ps1' is in the same directory as your profile." -ForegroundColor Yellow
	}
}
catch {
	Write-Error "Failed to load Yazi wrapper: $($_.Exception.Message)"
	Write-Host "You can still use PowerShell, but 'y' command will not be available." -ForegroundColor Yellow
}

# =================================
# StarShip読み込み
# =================================
Invoke-Expression (&starship init powershell)
