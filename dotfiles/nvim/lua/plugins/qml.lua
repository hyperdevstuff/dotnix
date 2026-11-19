return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- qmlls only reads QML_IMPORT_PATH when passed -E. The variable comes
      -- from home/dev.nix and points at the Qt and Quickshell module trees.
      vim.lsp.config("qmlls", { cmd = { "qmlls", "-E" } })
      vim.lsp.enable("qmlls")
    end,
  },
}
