# 🌈 Colorscheme Picker for Neovim

A simple and fast colorscheme picker for Neovim using [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim).
Supports live preview, persistent scheme saving, and toggling between favorite schemes.

---

## ✨ Features

- 🖼️ Telescope-powered fuzzy colorscheme picker
- 🔄 Toggle through your configured colorschemes
- 💾 Remembers last used scheme across sessions
- 💤 Lazy-loading compatible

---

## 📦 Installation

### [Lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "h598999/cs_picker.nvim",
  dependencies = { "nvim-telescope/telescope.nvim" },
  event = "VeryLazy",
  lazy = false,
  priority = 1000, -- make sure it loads early
  config = function()
    require("cs_picker").setup({
      -- Optional: specify preferred schemes
      user_colorSchemes = {
        tokyonight = { "night", "storm" },
        ["rose-pine"] = {"moon"},
        catppuccin = { "mocha", "macchiato" },
        gruvbox = {},
      },
    })
  end,
}
```

### Packer

```lua
use {
  "h598999/cs_picker.nvim",
  lazy = false,
  priority = 1000, -- make sure it loads early
  requires = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("cs_picker").setup()
  end
}
```

---

## ⚡ Usage

You can use the commands, and define your own keymaps

### Suggested keymaps:

```lua
vim.keymap.set("n", "<leader>fs", require("cs_picker").pick_colorscheme, { desc = "Pick colorscheme" })
vim.keymap.set("n", "<leader>cs", require("cs_picker").toggle_next, { desc = "Toggle colorscheme" })
```

### Available commands:

| Command               | Description                          |
|-----------------------|--------------------------------------|
| `:PickColorscheme`    | Open the fuzzy picker                |
| `:ToggleColorscheme`  | Cycle to the next configured scheme  |

---

## 🔧 Options

You can pass the following options to `setup()`:

| Option              | Type    | Description                                                |
|---------------------|---------|------------------------------------------------------------|
| `user_colorSchemes` | table   | A map of preferred base → variants                        |
| `scheme_file`       | string  | Where to store the selected scheme (default: Neovim cache) |
| `fallback`          | string  | Fallback scheme if saved one is not found                 |

---

## 📂 Example of `user_colorSchemes`

```lua
user_colorSchemes = {
  tokyonight = { "storm", "night" }, -- will match e.g. "tokyonight-night"
  ["rose-pine"] = {"moon"}, -- will match e.g. "rose-pine-moon"
  gruvbox = {},
  catppuccin = { "mocha" }, -- match "catppuccin-mocha"
}
```

---

## 🧠 How It Works

- On startup, reads the last used colorscheme from `scheme_file`
- Loads all installed colorschemes after `LazyDone`
- If `user_colorSchemes` is provided, filters to best matches
- `:ToggleColorscheme` rotates through this list
- `:PickColorscheme` opens a live preview Telescope picker

---

## ✅ Requirements

- Neovim ≥ 0.7
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

---

## 📃 License

MIT

---

## ✨ Inspired by

- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

