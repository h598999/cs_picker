describe("cs_picker setup", function()
  local cs_picker = require("cs_picker")

  it("exposes a setup function", function()
    assert.is_function(cs_picker.setup)
  end)

  it("exposes get_state", function()
    assert.is_function(cs_picker.get_state)
    local state = cs_picker.get_state()
    assert.is_table(state)
  end)

  it("initializes without error", function()
    local ok, err = pcall(cs_picker.setup, {})
    assert.is_true(ok, err)
  end)
end)

describe("cs_picker user_colorSchemes resolution", function()
  local real_get_runtime_file = vim.api.nvim_get_runtime_file

  before_each(function()
    -- Fake Neovim runtime response
    vim.api.nvim_get_runtime_file = function(pattern, _)
      if pattern == "colors/*.lua" then
        return {
          "/fake/colors/catppuccin.lua",
          "/fake/colors/catppuccin-mocha.lua",
          "/fake/colors/tokyodark.lua",
          "/fake/colors/ocean.lua",
        }
      elseif pattern == "colors/*.vim" then
        return {
          "/fake/colors/rose-pine.vim",
          "/fake/colors/rose-pine-moon.vim",
          "/fake/colors/onedark.vim",
          "/fake/colors/onedark_dark.vim",
          "/fake/colors/gruvbox.vim",
        }
      else
        return {}
      end
    end

    package.loaded["cs_picker"] = nil
  end)

  after_each(function()
    vim.api.nvim_get_runtime_file = real_get_runtime_file
  end)

  it("extracts the correct themes from installed based on user_colorSchemes", function()
    local cs_picker = require("cs_picker")
    cs_picker.reset()

    cs_picker.setup({
      user_colorSchemes = {
        catppuccin = { "mocha" },
        ["rose-pine"] = { "moon" },
        onedark = { "dark" },
        gruvbox = {},
      },
    })

    local expected = {
      "catppuccin",
      "catppuccin-mocha",
      "rose-pine",
      "rose-pine-moon",
      "onedark",
      "onedark_dark",
      "gruvbox",
    }

    table.sort(expected)

    cs_picker._init()

    local state = cs_picker.get_state()
    assert.are.same(expected, state.allColorSchemes)
  end)
end)

describe("cs_picker no user colorschemes provided", function()
  local real_get_runtime_file = vim.api.nvim_get_runtime_file

  before_each(function()
    -- Fake Neovim runtime response
    vim.api.nvim_get_runtime_file = function(pattern, _)
      if pattern == "colors/*.lua" then
        return {
          "/fake/colors/catppuccin.lua",
          "/fake/colors/catppuccin-mocha.lua",
          "/fake/colors/tokyodark.lua",
          "/fake/colors/ocean.lua",
        }
      elseif pattern == "colors/*.vim" then
        return {
          "/fake/colors/rose-pine.vim",
          "/fake/colors/rose-pine-moon.vim",
          "/fake/colors/onedark.vim",
          "/fake/colors/onedark_dark.vim",
          "/fake/colors/gruvbox.vim",
        }
      else
        return {}
      end
    end

    package.loaded["cs_picker"] = nil
  end)
    it("Gets all the installed colorschemes stored on the system", function()
        local cs_picker = require("cs_picker")
        cs_picker.reset()
        cs_picker.setup()
        cs_picker._init()

        local state = cs_picker.get_state()

        local expected = {
            "catppuccin",
            "catppuccin-mocha",
            "rose-pine",
            "rose-pine-moon",
            "onedark",
            "tokyodark",
            "ocean",
            "onedark_dark",
            "gruvbox",
        }

        table.sort(expected)

        assert.are_same(expected, state.allColorSchemes)
    end)
end)
