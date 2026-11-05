local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- The directory can exist but be an interrupted clone (only .git inside).
-- Treat that as missing and re-clone instead of failing `require("lazy")`.
local lazy_ok = vim.fn.isdirectory(lazypath) == 1
  and vim.fn.filereadable(lazypath .. "/lua/lazy/init.lua") == 1
if not lazy_ok then
  if vim.fn.isdirectory(lazypath) == 1 then
    vim.fn.delete(lazypath, "rf")
  end
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "kanagawa-dragon" } },
  -- config/ is a read-only Home Manager symlink into the nix store; keep the
  -- lockfile in the writable data dir instead.
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",
  -- No plugin needs luarocks; skip the hererocks/luarocks machinery.
  rocks = { enabled = false },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = true, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
