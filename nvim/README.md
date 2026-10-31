# Neovim (LazyVim)

[LazyVim](https://www.lazyvim.org/) をベースにした Neovim の設定です。
[公式 starter](https://github.com/LazyVim/starter) をもとにしています。

## ファイル構成

```
nvim/
├── init.lua             # エントリポイント (config.lazy を読み込むだけ)
├── lazyvim.json         # 有効にしている LazyVim Extras の一覧 (:LazyExtras が自動更新)
├── lazy-lock.json       # プラグインのバージョン固定 (:Lazy が自動更新)
├── stylua.toml          # Lua のフォーマット設定
└── lua/
    ├── config/
    │   ├── lazy.lua     # lazy.nvim のブートストラップと LazyVim の読み込み
    │   ├── options.lua  # オプション (デフォルトに追加・上書きする分のみ)
    │   ├── keymaps.lua  # キーマップ (同上)
    │   └── autocmds.lua # 自動コマンド (同上)
    └── plugins/         # プラグインの追加・LazyVim の設定の上書き (自動で読み込まれる)
        └── colorscheme.lua
```

`link.sh` で `~/.config/nvim` がこのディレクトリへのシンボリックリンクになります。

## インストール

```bash
# Neovim と依存ツール (mise/config.toml に記載済み)
mise install

# 設定ファイルのリンク
./link.sh

# 初回起動でプラグイン・Treesitter パーサー・LSP サーバーなどが自動でインストールされる
nvim
```

LazyVim は以下の外部コマンドを使います。いずれも `mise/config.toml` に記載しているため、`mise install` でまとめてインストールされます。

| コマンド | 用途 |
|---|---|
| `tree-sitter` | Treesitter パーサーのビルド |
| `rg` (ripgrep) | ファイル内容の検索 (`<leader>/`) |
| `fd` | ファイル名の検索 (`<leader><space>`) |
| `fzf` | ピッカー |
| `lazygit` | Git の操作 (`<leader>gg`) |
| `node` | 一部の LSP サーバー (Mason がインストール) の実行 |

C コンパイラ (`gcc`) と `curl` も必要です (`install.sh` で導入済み)。
インストール状況は `:checkhealth lazyvim` で確認できます。

### クリップボード (WSL)

`.zshenv` で Windows 側の PATH を除外しているため、Windows のクリップボードとの連携には `~/.local/bin/win32yank.exe` を使います。
`install.sh` が WSL 上でのみ配置し、Neovim が自動で検出します。

## 有効にしている Extras

`lazyvim.json` で管理しています。`:LazyExtras` で一覧を開き、`x` で有効 / 無効を切り替えられます (変更は `lazyvim.json` に保存されます)。

| Extra | 内容 |
|---|---|
| `lang.typescript` | TypeScript / JavaScript (vtsls) |
| `lang.json` | JSON (jsonls + SchemaStore) |
| `lang.markdown` | Markdown (marksman、プレビュー、レンダリング) |
| `lang.toml` | TOML (taplo) |
| `lang.yaml` | YAML (yamlls + SchemaStore) |
| `lang.docker` | Dockerfile / Compose (hadolint など) |
| `lang.rust` | Rust (rustaceanvim、crates.nvim) |
| `lang.go` | Go (gopls、gofumpt、goimports) |

## 基本操作

`<leader>` はスペースキーです。`<leader>` を押して少し待つと which-key がキーマップの候補を表示します。

| キー | 動作 |
|---|---|
| `<leader><space>` | ファイルを検索して開く |
| `<leader>/` | ファイル内容を検索 (grep) |
| `<leader>e` | ファイルツリー |
| `<leader>gg` | lazygit |
| `<leader>l` | プラグイン管理 (`:Lazy`) |
| `<leader>cm` | LSP サーバーなどの管理 (`:Mason`) |
| `<leader>sk` | キーマップの一覧 |
| `gd` / `gr` / `K` | 定義へ移動 / 参照一覧 / ホバー |
| `<leader>ca` | コードアクション |
| `<leader>cr` | リネーム |
| `<S-h>` / `<S-l>` | 前 / 次のバッファ |
| `<leader>bd` | バッファを閉じる |

すべてのキーマップは [公式ドキュメント](https://www.lazyvim.org/keymaps) を参照してください。

## カスタマイズ

- オプション・キーマップ・自動コマンドは `lua/config/` 以下の各ファイルに追記します。
- プラグインの追加や LazyVim の設定の上書きは、`lua/plugins/` に Lua ファイルを作成し、lazy.nvim の spec を返します。

```lua
-- lua/plugins/example.lua
return {
  -- プラグインの追加
  { "folke/zen-mode.nvim", cmd = "ZenMode" },

  -- LazyVim のプラグインの設定を上書き
  {
    "folke/snacks.nvim",
    opts = { dashboard = { enabled = false } },
  },

  -- LazyVim のプラグインを無効化
  { "akinsho/bufferline.nvim", enabled = false },
}
```

## 更新

`:Lazy` で `U` (update) を押すとプラグインが更新され、`lazy-lock.json` も更新されます。
更新後に問題があれば、`git checkout nvim/lazy-lock.json` してから `:Lazy restore` で元のバージョンに戻せます。
