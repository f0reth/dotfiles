# Yazi

ターミナルで動くファイルマネージャー [Yazi](https://yazi-rs.github.io/) の設定です。

## ファイル構成

```
yazi/
├── yazi.toml      # 基本設定 (表示・ソート・プレビュー・プラグインの登録)
├── keymap.toml    # キーバインド (デフォルトに追加・上書きする分のみ)
├── init.lua       # プラグインの setup と独自 linemode の定義
├── package.toml   # インストールしたプラグインの一覧 (ya pkg が自動生成・更新)
├── plugins/       # プラグイン本体 (ya pkg がインストール。自作の shell-wait.yazi 以外は git 管理外)
└── flavors/       # テーマ本体 (ya pkg がインストール。git 管理外)
```

`link.sh` で `~/.config/yazi` がこのディレクトリへのシンボリックリンクになります。

## インストール

```bash
# Yazi 本体 (mise/config.toml に記載済み)
mise install

# 設定ファイルのリンク
./link.sh

# package.toml に記載されたプラグインをインストール
ya pkg install
```

プレビューや一部の機能は外部コマンドを使います。いずれも `mise/config.toml` に記載しているため、`mise install` でまとめてインストールされます。

| コマンド | 用途 |
|---|---|
| `fd` | `s` でのファイル名検索 |
| `rg` (ripgrep) | `S` でのファイル内容検索 |
| `fzf` | `z` でのファイル / ディレクトリジャンプ |
| `zoxide` | `Z` でのディレクトリジャンプ |
| `jq` | JSON のプレビュー |
| `7zz` (7zip) | アーカイブのプレビュー・展開 |
| `ffmpeg` | 動画のサムネイル |
| `pdftoppm` (poppler-utils) | PDF のプレビュー |
| `magick` (ImageMagick) | HEIC・AVIF などの画像のプレビュー |

## 起動

```bash
y          # カレントディレクトリで起動
y ~/dotfiles
```

`y` は `zsh/.zshrc` で定義しているラッパー関数です。`q` で終了すると、最後に開いていたディレクトリにシェルも移動します。
移動せずに終了したい場合は `Q` を使います。

## 基本操作

`~` または `F1` でヘルプ (キーバインド一覧) を表示できます。

### 移動

| キー | 操作 |
|---|---|
| `j` / `k` | 下 / 上へ移動 |
| `h` / `l` | 親ディレクトリへ戻る / ディレクトリに入る |
| `gg` / `G` | 先頭 / 末尾へ移動 |
| `Ctrl-u` / `Ctrl-d` | 半ページ上 / 下へ移動 |
| `H` / `L` | 履歴を戻る / 進む |
| `gh` / `gc` / `gd` | `~` / `~/.config` / `~/Downloads` へ移動 |
| `g Space` | パスを入力して移動 |
| `K` / `J` | プレビューを上 / 下へスクロール |

### ファイル操作

| キー | 操作 |
|---|---|
| `o` / `Enter` | 開く |
| `O` | アプリを選んで開く |
| `Space` | 選択 / 選択解除 |
| `v` | ビジュアルモード (範囲選択) |
| `Ctrl-a` | すべて選択 |
| `y` / `x` | コピー / 切り取り |
| `p` / `P` | 貼り付け / 上書きして貼り付け |
| `d` / `D` | ゴミ箱へ移動 / 完全に削除 |
| `a` | 新規作成 (末尾を `/` にするとディレクトリ) |
| `r` | 名前の変更 (複数選択時は `$EDITOR` で一括変更) |
| `cc` / `cf` | パス / ファイル名をクリップボードにコピー |
| `.` | 隠しファイルの表示切り替え |
| `;` | シェルコマンドをバックグラウンドで実行 |
| `:` | シェルコマンドを実行し、Enter を押すまで出力を表示 (下記参照) |

### 検索・絞り込み

| キー | 操作 |
|---|---|
| `f` | 一覧を絞り込む |
| `/` / `?` | 次 / 前を検索 (`n` / `N` で移動) |
| `s` / `S` | fd でファイル名検索 / rg で内容検索 |
| `z` / `Z` | fzf / zoxide でジャンプ |

### 並び替え・表示

| キー | 操作 |
|---|---|
| `,m` / `,s` / `,n` | 更新日時 / サイズ / 名前 (自然順) で並び替え |
| `ms` / `mm` / `mp` / `mn` | 行末にサイズ / 更新日時 / 権限 / 何も表示しない |

### タブ

| キー | 操作 |
|---|---|
| `t t` | 新しいタブを開く |
| `1` 〜 `9` | タブを切り替え |
| `[` / `]` | 前 / 次のタブへ |
| `Ctrl-c` | タブを閉じる |

### このリポジトリで追加したキー

| キー | 操作 | 使用プラグイン |
|---|---|---|
| `F` | 絞り込み (1件になったら自動で入る / 開く) | smart-filter |
| `T` | プレビューを最大化 / 元に戻す | toggle-pane |
| `t p` | 親ディレクトリのペインを表示 / 非表示 | toggle-pane |
| `c m` | 選択中のファイルの権限を変更 | chmod |
| `:` | コマンドを実行し、Enter を押すまで出力を表示 (デフォルトは終了後すぐ Yazi に戻る) | shell-wait (自作) |
| `!` | 現在のディレクトリでシェルを開く (`exit` で Yazi に戻る) | - |
| `g r` | Git リポジトリのルートへ移動 | - |
| `g D` | `~/dotfiles` へ移動 | - |

## プラグイン

### 導入済みのプラグイン

| プラグイン | 内容 | 設定箇所 |
|---|---|---|
| [git](https://github.com/yazi-rs/plugins/tree/main/git.yazi) | 一覧に Git の変更状態を表示 | `yazi.toml`, `init.lua` |
| [full-border](https://github.com/yazi-rs/plugins/tree/main/full-border.yazi) | 各ペインを罫線で囲む | `init.lua` |
| [smart-filter](https://github.com/yazi-rs/plugins/tree/main/smart-filter.yazi) | 絞り込み結果が1件なら自動で入る / 開く | `keymap.toml` |
| [toggle-pane](https://github.com/yazi-rs/plugins/tree/main/toggle-pane.yazi) | ペインの最大化・非表示 | `keymap.toml` |
| [chmod](https://github.com/yazi-rs/plugins/tree/main/chmod.yazi) | 権限の変更 | `keymap.toml` |
| [starship](https://github.com/Rolv-Apneseth/starship.yazi) | ヘッダーに Starship のプロンプトを表示 | `init.lua` |
| [piper](https://github.com/yazi-rs/plugins/tree/main/piper.yazi) | 外部コマンドの出力をプレビューに表示 (`go.mod` / `go.sum` を bat でハイライト) | `yazi.toml` |
| shell-wait (自作) | コマンドを実行し、Enter を押すまで出力を表示 (`plugins/shell-wait.yazi`) | `keymap.toml` |

初回は以下でまとめてインストールします (`package.toml` が作成されます)。

```bash
ya pkg add yazi-rs/plugins:git yazi-rs/plugins:full-border yazi-rs/plugins:smart-filter yazi-rs/plugins:toggle-pane yazi-rs/plugins:chmod yazi-rs/plugins:piper Rolv-Apneseth/starship
```

### プラグインの追加方法

1. `ya pkg add` でインストールする

   ```bash
   # 公式プラグイン集 (yazi-rs/plugins) から追加する場合は「リポジトリ:プラグイン名」
   ya pkg add yazi-rs/plugins:smart-enter

   # 単体のリポジトリの場合は「ユーザー/リポジトリ」
   ya pkg add Rolv-Apneseth/starship
   ```

   `plugins/` にプラグインが入り、`package.toml` に追記されます。

2. プラグインの README に従って設定する

   - キーで呼び出すプラグイン → `keymap.toml` の `prepend_keymap` に追加

     ```toml
     { on = "l", run = "plugin smart-enter", desc = "Enter the child directory, or open the file" },
     ```

   - 起動時に setup が必要なプラグイン → `init.lua` に追加

     ```lua
     setup("full-border")
     ```

     `setup()` は `init.lua` で定義しているヘルパーで、プラグインが未インストールでもエラーにせずスキップします。

   - プレビューや fetcher として動くプラグイン → `yazi.toml` の `[plugin]` に追加

     `url` のパターンはパス全体にマッチします。ファイル名で指定する場合は `**/go.mod` のように `**/` を付けてください (`go.mod` や `*/go.mod` ではマッチしません)。

3. `package.toml` をコミットする

> [!NOTE]
> `keymap.toml` から呼び出すプラグインが未インストールだと、そのキーを押したときにエラーになります。
> `h` / `l` などの基本操作にはプラグインを割り当てないでください。

### 自作プラグインの追加方法

`plugins/<名前>.yazi/main.lua` を作成し、`.gitignore` に `!yazi/plugins/<名前>.yazi/` を追記して git 管理に含めます。
`ya pkg` は `package.toml` に記載したプラグインしか扱わないため、自作プラグインが上書き・削除されることはありません。

### テーマ (flavor) の追加方法

```bash
ya pkg add yazi-rs/flavors:catppuccin-mocha
```

`theme.toml` を作成して指定します。

```toml
[flavor]
dark = "catppuccin-mocha"
```

### 管理コマンド

```bash
ya pkg list      # インストール済みの一覧
ya pkg install   # package.toml の内容をインストール (別の環境での復元)
ya pkg upgrade   # すべてのプラグインを更新
ya pkg delete yazi-rs/plugins:chmod   # 削除
```

## 参考

- [公式ドキュメント](https://yazi-rs.github.io/docs/quick-start)
- [設定項目 (yazi.toml)](https://yazi-rs.github.io/docs/configuration/yazi)
- [キーバインド (keymap.toml)](https://yazi-rs.github.io/docs/configuration/keymap)
- [公式プラグイン集](https://github.com/yazi-rs/plugins)
- [プラグイン・テーマ一覧 (awesome-yazi)](https://github.com/AnirudhG07/awesome-yazi)
