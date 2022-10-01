local M = {}

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

			if #vim.lsp.get_active_clients({ bufnr = bufid }) == 0 then
				return
			end

			-- TODO: change to async true if you can write/callback after sync,
			-- callback = function(params)
			-- 	for _, bufnr in ipairs(buffers_in_format) do
			-- 		if params.buf == bufnr then
			-- 			-- :bufdo write
			-- 			break
			-- 		end
			-- 	end
			-- end
			vim.lsp.buf.format({
				bufnr = bufid,
				async = not loaded_config.save_after_format, -- Async when we dont need to save
				formatting_options = loaded_config.formatting_options,
				filter = loaded_config.filter
			})
			if loaded_config.save_after_format then
				vim.cmd("silent! write")
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
}

M.setup = function(config)
	config = config or {}
	config = vim.tbl_deep_extend('keep', config, default_config)

	loaded_config = config

	vim.api.nvim_create_user_command('FormatEnable', M.enable, {})
	vim.api.nvim_create_user_command('FormatDisable', M.disable, {})
	M.enable()
end

return M
