local M = {}

-- Variables
local allColorSchemes
local current_index
local selected_scheme
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

-- Local functions
local get_installed_colorschemes
local set_colorscheme
local set_user_colorschemes
local apply_scheme
local find_current_index
local find_base
local find_best_match
local read_scheme_file

-- Default config
local config = {
    scheme_file = vim.fn.stdpath("cache") .. "/last_colorscheme.txt",
    user_colorSchemes = nil,
    fallback  = "vim"
}

-- Private local and helper functions

apply_scheme = function()
    vim.schedule(function()
        pcall(vim.cmd.colorscheme(selected_scheme))
    end)
end


find_current_index = function()
    local i = 1
    for idx, val in ipairs(allColorSchemes) do
        if val == selected_scheme then
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

set_colorscheme = function(name)
    selected_scheme = name
    vim.cmd.colorscheme(name)
    vim.fn.writefile({ name }, config.scheme_file)
end


-- Public API
M.pick_colorscheme = function()
    local original_scheme = vim.g.colors_name or "default"
    pickers.new({}, {
        prompt_title = "Select Colorscheme",
        finder = finders.new_table {
            results = allColorSchemes,
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
                    pcall(vim.cmd.colorscheme, entry.value)
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
                    set_colorscheme(selection.value)
                end
            end)

            map("n", "<CR>", function()
                close_and_restore()
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    set_colorscheme(selection.value)
                end
            end)

            map("i", "<Esc>", function()
                actions.close(prompt_bufnr)
                pcall(vim.cmd.colorscheme, original_scheme)
            end)

            map("n", "<Esc>", function()
                actions.close(prompt_bufnr)
                pcall(vim.cmd.colorscheme, original_scheme)
            end)

            return true
        end,
    }):find()
end


M.toggle_next = function()
    if not allColorSchemes or #allColorSchemes == 0 then
        vim.notify("No colorschemes loaded. Did you call setup()?", vim.log.levels.ERROR)
        return
    end
    current_index = (current_index % #allColorSchemes) + 1
    set_colorscheme(allColorSchemes[current_index])
    print("Colorscheme: " .. allColorSchemes[current_index])
end

M.setup = function(opts)
  config = vim.tbl_extend("force", config, opts or {})

  local has_lazy = vim.fn.exists("#User#LazyDone") == 1
  vim.api.nvim_create_autocmd(has_lazy and "User" or "VimEnter", {
      pattern = has_lazy and "LazyDone" or nil,
      once = true,
      callback = function()
          if config.user_colorSchemes and not vim.tbl_isempty(config.user_colorSchemes) then
              allColorSchemes = set_user_colorschemes(config.user_colorSchemes)
          else
              allColorSchemes = get_installed_colorschemes()
          end
          selected_scheme = read_scheme_file(config.scheme_file,config.fallback)
          apply_scheme()
          current_index = find_current_index()
      end
  })
  vim.api.nvim_create_user_command("PickColorscheme", M.pick_colorscheme, { desc = "Telescope-based colorscheme picker"})
  vim.api.nvim_create_user_command("ToggleColorscheme", M.toggle_next, { desc = "Cycle through available colorschemes"})
end

return M
