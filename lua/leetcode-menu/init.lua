local component = require("leetcode-ui.component")
local log = require("leetcode.logger")
local utils = require("leetcode-menu.utils")
local config = require("leetcode.config")

local Text = require("nui.text")
local Line = require("nui.line")

---@class lc-menu
---@field layout lc-ui.Layout
---@field bufnr integer
---@field winid integer
---@field tabpage integer
---@field cursor lc-menu.cursor
local menu = {} ---@diagnostic disable-line
menu.__index = menu

---@type lc-menu
_LC_MENU = {} ---@diagnostic disable-line

local function tbl_keys(t)
    local keys = vim.tbl_keys(t)
    if not keys then return end
    table.sort(keys)
    return keys
end

function menu:clear() vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {}) end

function menu:redraw() self:draw() end

function menu:draw()
    self:clear()

    self.layout:draw(self)
    self:cursor_adjust()
end

function menu:cursor_adjust()
    local keys = tbl_keys(self.layout.buttons)
    if not keys then return end
    vim.api.nvim_win_set_cursor(self.winid, { keys[self.cursor.idx], 95 })
end

---@private
function menu:autocmds()
    local group_id = vim.api.nvim_create_augroup("leetcode_menu", {})

    vim.api.nvim_create_autocmd("WinResized", {
        group = group_id,
        buffer = self.bufnr,
        callback = function() self:redraw() end,
    })

    vim.api.nvim_create_autocmd("CursorMoved", {
        group = group_id,
        buffer = self.bufnr,
        callback = function() self:cursor_move() end,
    })
end

function menu:cursor_move()
    local c_curr = vim.api.nvim_win_get_cursor(self.winid)[1]
    local c_prev = self.cursor.prev

    if c_curr == c_prev then return self:cursor_adjust() end

    local keys = tbl_keys(self.layout.buttons)
    if not keys then return end

    if c_prev then
        if c_curr > c_prev then
            self.cursor.idx = math.min(self.cursor.idx + 1, #keys)
        else
            self.cursor.idx = math.max(self.cursor.idx - 1, 1)
        end
    end

    local c_next = keys[self.cursor.idx]
    vim.api.nvim_win_set_cursor(self.winid, { c_next, 95 })

    self.cursor.prev = c_next
    self.cursor.curr = c_next
end

function menu:cursor_reset()
    local keys = tbl_keys(self.layout.buttons)
    if not keys then return end

    self.cursor.idx = 1
    self.cursor.curr = keys[self.cursor.idx]
    self.cursor.prev = keys[self.cursor.idx]

    self:cursor_adjust()
end

---@param layout layouts
function menu:set_layout(layout)
    self:cursor_reset()

    local ok, res = pcall(require, "leetcode-menu.theme." .. layout)
    if ok then self.layout = res end

    self:redraw()
end

---@private
function menu:keymaps()
    -- self.split:map("n", "<cr>", function()
    -- end)

    vim.keymap.set("n", "<cr>", function()
        local row = vim.api.nvim_win_get_cursor(self.winid)[1]
        self.layout:handle_press(row)
    end, {})
end

function menu:mount()
    self:keymaps()
    self:autocmds()

    self:draw()
end

function menu:init()
    local bufnr = vim.api.nvim_get_current_buf()
    local winid = vim.api.nvim_get_current_win()
    local tabpage = vim.api.nvim_get_current_tabpage()
    vim.api.nvim_buf_set_name(bufnr, "")
    vim.api.nvim_set_current_tabpage(1)

    utils.apply_opt_local({
        bufhidden = "wipe",
        buflisted = false,
        matchpairs = "",
        swapfile = false,
        buftype = "nofile",
        filetype = "leetcode.nvim",
        synmaxcol = 0,
        wrap = false,
        colorcolumn = "",
        foldlevel = 999,
        foldcolumn = "0",
        cursorcolumn = false,
        cursorline = false,
        number = false,
        relativenumber = false,
        list = false,
        spell = false,
        signcolumn = "no",
    })

    local logged_in = config.auth.is_signed_in
    local layout = logged_in and "menu" or "signin"
    local ok, l = pcall(require, "leetcode-menu.theme." .. layout)
    assert(ok)

    local obj = setmetatable({
        bufnr = bufnr,
        winid = winid,
        tabpage = tabpage,
        layout = l,
        cursor = {
            idx = 1,
        },
    }, self)

    _LC_MENU = obj
    return obj:mount()
end

return menu
