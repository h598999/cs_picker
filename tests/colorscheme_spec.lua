local cs_picker = require("cs_picker")

describe("colorscheme_picker", function()
  it("finds the correct index after injecting state", function()
    cs_picker._test.set_state({
      allColorSchemes = { "gruvbox", "tokyonight-night", "catppuccin-mocha" },
      selected_scheme = "tokyonight-night"
    })

    local idx = cs_picker._test.find_current_index()

    assert.equals(2, idx)
  end)
end)

describe("colorscheme_picker", function()
  it("sets the user colorschemes correctly", function()
    local cs = require("cs_picker")
    local match_fn = cs._test.set_user_colorschemes

    local _G_get = vim.api.nvim_get_runtime_file
    vim.api.nvim_get_runtime_file = function(_, _)
      return {
        "/fake/path/colors/tokyonight-night.lua",
        "/fake/path/colors/gruvbox.vim",
        "/fake/path/colors/rose-pine-moon.lua",
        "/fake/path/colors/rose-pine.lua",
        "/fake/path/colors/tokyonight.lua",
      }
    end

    local result = match_fn({
      tokyonight = { "night" },
      gruvbox = {},
      ["rose-pine"] = { "moon" },
    })

    table.sort(result)
    assert.are.same({
      "gruvbox",
      "rose-pine",
      "rose-pine-moon",
      "tokyonight",
      "tokyonight-night",
    }, result)

    -- Restore
    vim.api.nvim_get_runtime_file = _G_get
  end)

  it("Should get all the installed colorschemes", function ()
        local cs = require("cs_picker")
  local get = cs._test.get_installed_colorschemes

  local _G_get = vim.api.nvim_get_runtime_file
  vim.api.nvim_get_runtime_file = function(pattern, _)
      if pattern == "colors/*.lua" then
          return {
              "/fake/colors/gruvbox.lua",
              "/fake/colors/tokyonight-night.lua",
          }
      elseif pattern == "colors/*.vim" then
          return {
              "/fake/colors/gruvbox.vim",
              "/fake/colors/tokyonight.vim",
              "/fake/colors/rose-pine-moon.vim",
          }
      end
      return {}
  end

  local result = get()
  table.sort(result)

  assert.are.same({
      "gruvbox",
      "rose-pine-moon",
      "tokyonight",
      "tokyonight-night",
  }, result)

  -- Restore
  vim.api.nvim_get_runtime_file = _G_get
  end)
end)
