-- 補完候補の確定を Enter から Tab に変更する
-- super-tab プリセットは <CR> を割り当てないため、Enter は常に通常の改行になる
-- (IME の変換確定の Enter は IME 側で処理されるため Neovim には届かない)
return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "super-tab",
      },
    },
  },
}
