-- clangd は Mason で入れず、Scoop (Windows: llvm) / apt (Linux: clangd) で入れたものを使う
-- (clang-format / clang-tidy と同じ LLVM のバージョンに揃えるため)
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          mason = false,
        },
      },
    },
  },
}
