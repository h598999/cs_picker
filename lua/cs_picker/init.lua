local M = {}

-- Variables
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

-- Local functions
local get_installed_colorschemes
local set_colorscheme_and_save
local set_user_colorschemes
local apply_selected_scheme
local apply_scheme
local find_current_index
local find_base
local find_best_match
local read_scheme_file

local State = {
    allColorSchemes = {},
    current_index = 1,
    selected_scheme = "default"
}

local config = {
    scheme_file = vim.fn.stdpath("cache") .. "/last_colorscheme.txt",
    user_colorSchemes = nil,
    fallback  = "vim",
    auto_apply = true
}

-- Private local and helper functions

apply_selected_scheme = function()
    vim.schedule(function()
        -- local ok, err = pcall(vim.cmd.colorscheme, State.selected_scheme)
        -- if not ok then
        --     vim.notify("Failed to apply colorschemes from apply_selected_scheme: "..err, vim.log.levels.ERROR)
        -- end
        apply_scheme(State.selected_scheme)
    end)
end

-- @param colorscheme string
apply_scheme = function(colorscheme)
    local ok, err = pcall(vim.cmd.colorscheme, colorscheme)
    if not ok then
        vim.notify("Failed to apply colorschemes: from apply_scheme"..err, vim.log.levels.ERROR)
    end
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })         -- main text area
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })       -- unfocused windows
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })    -- floating windows
    vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })     -- gutter
    vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })    -- ~ lines

    -- Make completion and documentation window backgrounds transparent
    vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })          -- Completion menu
    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#333333" })    -- Selected item
    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#555555" })  -- Scrollbar
    vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })      -- Scrollbar background
    vim.api.nvim_set_hl(0, "CmpDocumentation", { bg = "none" }) -- Doc window

    -- Item abbreviation (main text)
    vim.api.nvim_set_hl(0, "CmpItemAbbr",         { fg = "#cdd6f4", bg = "none" })
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatch",    { fg = "#89b4fa", bg = "none", bold = true })  -- matching part
    vim.api.nvim_set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#94e2d5", bg = "none", italic = true })

    -- Item kind (Function, Variable, etc.)
    vim.api.nvim_set_hl(0, "CmpItemKind",         { fg = "#fab387", bg = "none" })

    -- Menu source label ([LSP], [Buffer], etc.)
    vim.api.nvim_set_hl(0, "CmpItemMenu",         { fg = "#7f849c", bg = "none", italic = true })

    -- Border for floating windows (optional)
    vim.api.nvim_set_hl(0, "FloatBorder",         { fg = "#89b4fa", bg = "#1e1e2e" })
    vim.api.nvim_set_hl(0, "NormalFloat",         { bg = "#1e1e2e" })
end


find_current_index = function()
    local i = 1
    for idx, val in ipairs(State.allColorSchemes) do
        if val == State.selected_scheme then
            i = idx
            break
        end
    end
    return i
end


read_scheme_file = function(scheme_file, fallback)
    local ok, lines = pcall(vim.fn.readfile, scheme_file)
    local selected = (ok and lines[1]) and lines[1] or fallback
    return selected
end

get_installed_colorschemes = function()
    local colorSchemes = {}
    local seenColors = {}

    for _, path in ipairs(vim.api.nvim_get_runtime_file("colors/*.lua", true)) do
        local name = vim.fn.fnamemodify(path, ":t:r")
        if not seenColors[name] then
            table.insert(colorSchemes, name)
            seenColors[name] = true
        end
    end

    for _, path in ipairs(vim.api.nvim_get_runtime_file("colors/*.vim", true)) do
        local name = vim.fn.fnamemodify(path, ":t:r")
        if not seenColors[name] then
            table.insert(colorSchemes, name)
            seenColors[name] = true
        end
    end
    return colorSchemes
end

set_user_colorschemes = function(color_map)
  local installed = get_installed_colorschemes()
  local found, seen   = {}, {}

  local function add(name)
    if name and not seen[name] then
      table.insert(found, name)
      seen[name] = true
    end
  end

  for base, variants in pairs(color_map or {}) do
    local baseMatch = find_base(base, installed)
    if baseMatch then
        add(baseMatch)
    end
    for _, variant in ipairs(variants) do
      local match = find_best_match(base, variant, installed)
      if match then
        add(match)
      else
        vim.notify(
          ("No installed scheme matches %s + %s"):format(base, variant),
          vim.log.levels.WARN
        )
      end
    end
  end
  return found
end


find_base = function(base, installed)
    for _, scheme in ipairs(installed) do
        local s = scheme:lower()
        if s == base:lower() then
            return scheme
        end
    end
    return nil
end


find_best_match = function(base, variant, installed)
    local delimiters = { "-", "_", " ", "" }
    local base_l, variant_l = base:lower(), variant:lower()

    local cand = {}
    for _, d in ipairs(delimiters) do
        cand[#cand + 1] = base_l .. d .. variant_l
    end

    for _, scheme in ipairs(installed) do
        local s = scheme:lower()
        for _, wanted in ipairs(cand) do
            if s == wanted then
                return scheme
            end
        end
    end
    return nil
end

local function save_scheme(colorscheme)
    local ok, err = pcall(vim.fn.writefile, { colorscheme }, config.scheme_file)
    if not ok then
        vim.notify("Failed to save colorscheme to file: "..err, vim.log.levels.ERROR)
    end
end

set_colorscheme_and_save = function(colorscheme)
    State.selected_scheme = colorscheme
    apply_scheme(colorscheme)
    save_scheme(colorscheme)
end

M.get_current_colorscheme = function()
    local selected = read_scheme_file(config.scheme_file, config.fallback)
    print("Current scheme: ", selected)
end


-- Public API
M.pick_colorscheme = function()
    pickers.new({}, {
        prompt_title = "Select Colorscheme",
        finder = finders.new_table {
            results = State.allColorSchemes,
            entry_maker = function(name)
                return {
                    value = name,
                    display = name,
                    ordinal = name,
                    filename = vim.api.nvim_buf_get_name(0),
                }
            end
        },
        sorter = conf.generic_sorter({}),
        previewer = conf.file_previewer({}),
        attach_mappings = function(prompt_bufnr, map)
            local preview_applied = nil
            local timer = vim.loop.new_timer()
            timer:start(100,100, vim.schedule_wrap(function()
                local entry = action_state.get_selected_entry()
                if entry and entry.value and entry.value ~= preview_applied then
                    apply_scheme(entry.value)
                    preview_applied = entry.value
                end
            end))

            local function close_and_restore()
                timer:stop()
                timer:close()
                actions.close(prompt_bufnr)
            end
            map("i", "<CR>", function()
                close_and_restore()
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    set_colorscheme_and_save(selection.value)
                end
            end)

            map("n", "<CR>", function()
                close_and_restore()
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    set_colorscheme_and_save(selection.value)
                end
            end)

            map("i", "<Esc>", function()
                close_and_restore()
                apply_selected_scheme()
            end)

            map("n", "<Esc>", function()
                close_and_restore()
                apply_selected_scheme()
            end)

            return true
        end,
    }):find()
end


M.toggle_next = function()
    if not State.allColorSchemes or #State.allColorSchemes == 0 then
        vim.notify("No colorschemes loaded. Did you call setup()?", vim.log.levels.ERROR)
        return
    end
    State.current_index = (State.current_index % #State.allColorSchemes) + 1
    set_colorscheme_and_save(State.allColorSchemes[State.current_index])
    print("Colorscheme: " .. State.allColorSchemes[State.current_index])
end

local function configure(opts)
  config = vim.tbl_extend("force", config, opts or {})
end

local function _init()
    if config.user_colorSchemes and not vim.tbl_isempty(config.user_colorSchemes) then
        State.allColorSchemes = set_user_colorschemes(config.user_colorSchemes)
    else
        State.allColorSchemes = get_installed_colorschemes()
    end
    table.sort(State.allColorSchemes)
    State.selected_scheme = read_scheme_file(config.scheme_file, config.fallback)
    apply_selected_scheme()
    State.current_index = find_current_index()
end

local function initialize()

  local has_lazy = vim.fn.exists("#User#LazyDone") == 1
  vim.api.nvim_create_autocmd(has_lazy and "User" or "VimEnter", {
    pattern = has_lazy and "LazyDone" or nil,
    once = true,
    callback = function()
      if config.auto_apply then
        _init()
      end
    end,
  })

  vim.api.nvim_create_user_command("PickColorscheme", M.pick_colorscheme, { desc = "Telescope-based colorscheme picker" })
  vim.api.nvim_create_user_command("ToggleColorscheme", M.toggle_next, { desc = "Cycle through available colorschemes" })
end

M.setup = function(opts)
  configure(opts)
  initialize()
end

M._state = State

function M.get_state()
    return State
end

function M.set_state(new_state)
    State.allColorSchemes = new_state.allColorSchemes or {}
    State.current_index = new_state.current_index or 1
    State.selected_scheme = new_state.selected_scheme or "default"
end

M._init = _init

function M.reset()
    M.set_state({})
    configure({})
end

return M
