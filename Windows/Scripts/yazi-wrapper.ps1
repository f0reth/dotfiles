function Invoke-Yazi {
	param(
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]]$Arguments
	)

	try {
		# Yaziコマンドの存在確認
		if (-not (Get-Command yazi -ErrorAction SilentlyContinue)) {
			Write-Error "Error: 'yazi' command not found. Please install Yazi first." -ErrorAction Stop
		}

		# 一時ファイルの作成
		$tmpfile = Join-Path $env:TEMP "yazi-cwd.$((Get-Random))"
		Write-Verbose "Created temporary file: $tmpfile"

		# Yaziの起動（引数も渡す）
		Write-Verbose "Starting Yazi with arguments: $($Arguments -join ' ')"
		if ($Arguments) {
			& yazi $Arguments --cwd-file="$tmpfile"
		} else {
			& yazi --cwd-file="$tmpfile"
		}

		# Yaziの終了コードをチェック
		if ($LASTEXITCODE -ne 0) {
			Write-Warning "Yazi exited with code: $LASTEXITCODE"
		}

		# ファイルが存在するかチェック
		if (Test-Path $tmpfile) {
			Write-Verbose "Reading directory path from temporary file"

			# ディレクトリパスを読み取り
			$cwd = Get-Content $tmpfile -Raw -ErrorAction Stop | ForEach-Object { $_.Trim() }

			# 空でなければディレクトリを変更
			if ($cwd) {
					if (Test-Path $cwd -PathType Container) {
						Write-Verbose "Changing directory to: $cwd"
						Set-Location $cwd -ErrorAction Stop
						Write-Host "Changed directory to: " -NoNewline -ForegroundColor Green
						Write-Host $cwd -ForegroundColor Cyan
					} else {
						Write-Warning "Directory does not exist or is not accessible: $cwd"
					}
			} else {
				Write-Verbose "No directory path found in temporary file"
			}
		} else {
			Write-Verbose "Temporary file not found - Yazi may have been closed without selecting a directory"
		}
	}
	catch [System.Management.Automation.CommandNotFoundException] {
		Write-Error "Error: Command not found - $($_.Exception.Message)" -ErrorAction Continue
	}
	catch [System.UnauthorizedAccessException] {
		Write-Error "Error: Access denied - $($_.Exception.Message)" -ErrorAction Continue
	}
	catch [System.IO.IOException] {
		Write-Error "Error: File I/O error - $($_.Exception.Message)" -ErrorAction Continue
	}
	catch {
		Write-Error "Unexpected error occurred: $($_.Exception.Message)" -ErrorAction Continue
		Write-Error "Error details: $($_.Exception.GetType().FullName)" -ErrorAction Continue

		# デバッグ情報（詳細モード時のみ）
		if ($VerbosePreference -eq 'Continue') {
			Write-Error "Stack trace: $($_.ScriptStackTrace)" -ErrorAction Continue
		}
	}
	finally {
		# 一時ファイルのクリーンアップ
		if ($tmpfile -and (Test-Path $tmpfile)) {
			try {
				Remove-Item $tmpfile -Force -ErrorAction Stop
				Write-Verbose "Cleaned up temporary file: $tmpfile"
			}
			catch {
				Write-Warning "Failed to clean up temporary file: $tmpfile - $($_.Exception.Message)"
			}
		}
	}
}

# エイリアスの設定
Set-Alias -Name y -Value Invoke-Yazi -Description "Launch Yazi file manager with directory synchronization"
