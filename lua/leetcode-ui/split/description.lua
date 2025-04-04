local config = require("leetcode.config")

local Group = require("leetcode-ui.group")
local Padding = require("leetcode-ui.lines.padding")
local Split = require("leetcode-ui.split")
local Parser = require("leetcode.parser")

local log = require("leetcode.logger")
local utils = require("leetcode.utils")

local t = require("leetcode.translator")

---@class lc.ui.Description : lc-ui.Split
---@field question lc.ui.Question
---@field images table<string, Image>
local Description = Split:extend("LeetDescription")

local group_id = vim.api.nvim_create_augroup("leetcode_description", { clear = true })

function Description:autocmds()
    vim.api.nvim_create_autocmd("WinResized", {
        group = group_id,
        buffer = self.bufnr,
        callback = function()
            self:draw()
        end,
    })
end

function Description:mount()
    Description.super.mount(self)
    self:populate()
    vim.api.nvim_buf_set_name(self.bufnr, "Task")
    local ui_utils = require("leetcode-ui.utils")
    ui_utils.buf_set_opts(self.bufnr, {
        matchpairs = "",
        swapfile = false,
        filetype = "markdown",
        synmaxcol = 0,
        buflisted = true,
        bufhidden = "hide",
    })
    --[[
    ui_utils.win_set_opts(self.winid, {
        wrap = true,
        colorcolumn = "",
        foldlevel = 999,
        foldcolumn = "1",
        cursorcolumn = false,
        cursorline = false,
        number = false,
        relativenumber = false,
        list = false,
        spell = false,
        signcolumn = "no",
        linebreak = true,
    })
      --]]
    self:draw()
    self:autocmds()
    return self
end

function Description:draw()
    Description.super.draw(self)
end

function Description:toggle_stats()
    self.show_stats = not self.show_stats
    self:populate()
    self:draw()
end

---@private
function Description:populate()
    local q = self.question.q

    local header = Group({}, {
        position = "center",
    })

    header:append(self.question.cache.link or "", "leetcode_alt")
    header:endgrp()

    header:insert(Padding(1))

    header:append(q.frontend_id .. ". ", "leetcode_normal")
    header:append(utils.translate(q.title, q.translated_title))
    if q.is_paid_only then
        header:append(" " .. t("Premium"), "leetcode_medium")
    end
    header:endgrp()

    local show_stats = self.show_stats

    if show_stats then
        header:append(t(q.difficulty), "leetcode_" .. q.difficulty:lower())
    else
        header:append("????", "leetcode_list")
    end

    if config.icons.hl.status[self.question.cache.status] then
        local s = config.icons.hl.status[self.question.cache.status]
        header:append(" "):append(s[1], s[2])
    end

    header:append((" %s "):format(config.icons.bar))

    local likes = show_stats and q.likes or "___"
    header:append(likes .. " ", "leetcode_alt")

    local dislikes = show_stats and q.dislikes or "___"
    if not config.is_cn then
        header:append((" %s "):format(dislikes), "leetcode_alt")
    end

    header:append((" %s "):format(config.icons.bar))

    local ac_rate = show_stats and q.stats.acRate or "__%"
    local total_sub = show_stats and q.stats.totalSubmission or "__"
    header:append(("%s %s %s"):format(ac_rate, t("of"), total_sub), "leetcode_alt")
    if not vim.tbl_isempty(q.hints) then
        header:append((" %s "):format(config.icons.bar))
        header:append("󰛨 " .. t("Hints"), "leetcode_hint")
    end
    header:endgrp()

    local contents = Parser:parse(utils.translate(q.content, q.translated_content))

    self.renderer:replace({
        header,
        Padding(3),
        contents,
    })
end

---@param parent lc.ui.Question
function Description:init(parent)
    Description.super.init(self, {
        relative = "editor",
        position = config.user.description.position,
        size = config.user.description.width,
        enter = false,
        focusable = true,
    })

    self.question = parent
    self.show_stats = config.user.description.show_stats
    self.images = {}
end

---@type fun(parent: lc.ui.Question): lc.ui.Description
local LeetDescription = Description

return LeetDescription
