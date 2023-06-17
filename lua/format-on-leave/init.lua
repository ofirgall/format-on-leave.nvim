local M = {}

local lsp_progress = require('format-on-leave.lsp_progress')

local api = vim.api
local auto_format_cmd = -1
local loaded_config = {}

M.disable = function()
	if auto_format_cmd ~= -1 then
		vim.api.nvim_del_autocmd(auto_format_cmd)
		auto_format_cmd = -1
	end
end
-- Backwards compatibility
M.disable_auto_format = M.disable

local function list_buf_wins(buf)
	local wins = api.nvim_list_wins()
	local buf_wins = {}
	for _, win in ipairs(wins) do
		local b = api.nvim_win_get_buf(win)
		if b == buf then
			table.insert(buf_wins, win)
		end
	end

	return buf_wins
end

local function get_win_cursors(wins)
	local wins_cursors = {}
	for _, win in ipairs(wins) do
		wins_cursors[win] = api.nvim_win_get_cursor(win)
	end

	return wins_cursors
end

M.enable = function()
	M.disable()

	auto_format_cmd = vim.api.nvim_create_autocmd('WinLeave', {
		pattern = loaded_config.pattern,
		callback = function(params)
			local bufid = params.buf
			local diff = api.nvim_get_option_value('diff', { buf = bufid })
			if diff then
				return
			end

			local readonly = api.nvim_get_option_value('readonly', { buf = bufid })
			if readonly then
				return
			end

			if not lsp_progress.is_buffer_ready(bufid) then
				return
			end

			-- Save all cursor positions for all in-active windows (to fix sumenko lua bug)
			local buf_wins = list_buf_wins(bufid)
			local wins_cursors = get_win_cursors(buf_wins)

			-- TODO: change to async true if you can write/callback after sync,
			-- callback = function(params)
			-- 	for _, bufnr in ipairs(buffers_in_format) do
			-- 		if params.buf == bufnr then
			-- 			-- :bufdo write
			-- 			break
			-- 		end
			-- 	end
			-- end
			local async = not loaded_config.save_after_format -- Async when we dont need to save

			if loaded_config.format_func then
				loaded_config.format_func(async)
			else
				vim.lsp.buf.format({
					bufnr = bufid,
					async = async,
					formatting_options = loaded_config.formatting_options,
					filter = loaded_config.filter
				})
			end

			if loaded_config.save_after_format then
				vim.cmd("silent! write")
			end

			-- Restore cursor positions (to fix sumenko lua bug)
			for win, cursor in pairs(wins_cursors) do
				api.nvim_win_set_cursor(win, cursor)
			end
			-- table.insert(buffers_in_format, buf)
		end
	})
end

-- Backwards compatibility
M.enable_auto_format = M.enable

local default_config = {
	pattern = { '*' },
	formatting_options = nil,
	filter = nil,
	save_after_format = true,
	format_func = nil,
}

M.setup = function(config)
	config = config or {}
	config = vim.tbl_deep_extend('keep', config, default_config)

	loaded_config = config

	vim.api.nvim_create_user_command('FormatEnable', M.enable, {})
	vim.api.nvim_create_user_command('FormatDisable', M.disable, {})
	M.enable()
	lsp_progress.setup()
end

return M
