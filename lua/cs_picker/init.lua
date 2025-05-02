local M = {}
local user_variants = {}
local user_colorSchemes = {}

local defaults = {
    scheme_file = vim.fn.stdpath("cache") .. "/last_colorscheme.txt",
    fallback  = "vim"
}

function M.setup(opts)
    opts = vim.tbl_extend("force", defaults, opts or {})
    M._apply_scheme(opts.scheme_file, opts.fallback)
end

function M._apply_scheme(scheme_file, fallback)
    local ok, lines = pcall(vim.fn.readfile, scheme_file)
    local selected = (ok and lines[1]) and lines[1] or fallback
    vim.schedule(function()
        vim.cmd.colorscheme(selected)
        vim.print("Applying scheme " .. selected)
    end)
end

local scheme_file = vim.fn.stdpath("cache") .. "/last_colorscheme.txt"

function M.register_variants(variant_table)
    user_variants = variant_table or {}
end

local function get_installed_colorschemes()
    local colorSchemes = {}
    local seenColors = {}

    for _, path in ipairs(vim.api.nvim_get_runtime_file("colors/*.vim", true)) do
        local name = vim.fn.fnamemodify(path, ":t:r")
        if not seenColors[name] then
            table.insert(colorSchemes, name)
            seenColors[name] = true
        end
    end
    for _, path in ipairs(vim.api.nvim_get_runtime_file("colors/*.lua",true)) do
        local name = vim.fn.fnamemodify(path, ":t:r")
        if not seenColors[name] then
            table.insert(colorSchemes, name)
            seenColors[name] = true
        end
    end

    local expanded = {}
    for _, color in ipairs(colorSchemes) do
        if user_variants[color] then
            for _, variant in ipairs(user_variants[color]) do
                table.insert(expanded, color .. ":" .. variant)
            end
        else
            table.insert(expanded, color)
        end
    end
    return expanded
end

local function find_best_match(base, variant, installed_schemes)
    local candidates ={
        base .. "-" .. variant,
        base .. "_" .. variant,
        base .. " " .. variant,
        base .. variant,
    }

    for _, cand in ipairs(candidates) do
        for _, installed in ipairs(installed_schemes) do
            if installed:lower() == cand:lower() then
                return installed
            end
        end
    end
    return nil
end

function M.set_user_colorschemes(colors_table)
    local seen = {}
    local all_installed = get_installed_colorschemes()
    for base, variants in pairs(colors_table or {}) do
        if #variants > 0 then
            for _, variant in ipairs(variants) do
                local match = find_best_match(base,variant, all_installed)
                if match and not seen[match] then
                    table.insert(user_colorSchemes, match)
                    seen[match] = true
                end
            end
        else
            table.insert(user_colorSchemes, base)
        end
    end
end

M.pick_colorscheme = function()
    local themes
    if next(user_colorSchemes) ~= nil then
        themes = user_colorSchemes
    else
        themes = get_installed_colorschemes()
    end
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values
    local original_scheme = vim.g.colors_name or "default"
    pickers.new({}, {
        prompt_title = "Select Colorscheme",
        finder = finders.new_table {
            results = themes,
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
                    vim.cmd.colorscheme(selection.value)
                    vim.fn.writefile({ selection.value }, scheme_file)
                end
            end)

            map("n", "<CR>", function()
                close_and_restore()
                local selection = action_state.get_selected_entry()
                if selection and selection.value then
                    vim.cmd.colorscheme(selection.value)
                    vim.fn.writefile({ selection.value }, scheme_file)
                end
            end)


            -- Cancel -> restore original
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

M.init = function()
 local ok, lines = pcall(vim.fn.readfile, scheme_file)
  local selected = (ok and lines[1]) and lines[1] or "vim"
  -- print(vim.fn.stdpath("cache"))
  print("Applying colorscheme from plugin:", selected)
  pcall(vim.cmd.colorscheme, selected)
end

M.toggle_next = function()
    local colorSchemes = get_installed_colorschemes()
    local current = vim.fn.readfile(scheme_file)[1] or colorSchemes[1]
    local i = 1
    for idx, val in ipairs(colorSchemes) do
        if val == current then
            i = idx
            break
        end
    end
    i = (i % #colorSchemes) + 1
    M.set_colorscheme(colorSchemes[i])
    print("Colorscheme: " .. colorSchemes[i])
end

M.set_colorscheme = function(name)
  vim.cmd.colorscheme(name)
  vim.fn.writefile({ name }, scheme_file)
end

function M.debug_print_colorschemes()
    local schemes = get_installed_colorschemes()
    print(vim.inspect(schemes))
end

return M
