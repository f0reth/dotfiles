# 使い方

Winget のみを使ってインストールします。
Winget が利用できない場合は自動インストールを行います。

## インストール

```powershell
# 通常の実行
.\installer.ps1

# すべての利用規約を自動承認
.\installer.ps1 -AcceptAll

# 強制再インストール
.\installer.ps1 -Force

# 詳細ログ付き
.\installer.ps1 -Verbose
```

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

## Yazi 用スクリプトの使い方

```powershell
PowerShell Profile Directory/
├── Scripts\
│   └── yazi-wrapper.ps1              # Yaziラッパースクリプト
└── Microsoft.PowerShell_profile.ps1  # メインプロファイル
```

```powershell
# 通常の使用
y

# 詳細情報付きで実行（デバッグ時に有用）
y -Verbose

# 特定のディレクトリで開始
y C:\Users
```
