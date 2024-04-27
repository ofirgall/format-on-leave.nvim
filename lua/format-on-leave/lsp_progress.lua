local M = {}

local READY_CLIENTS = {}
local AMOUNT_IN_PROGRESS = {}
local CLIENT_TIMER = {}
local uv = vim.loop

function M.is_buffer_ready(bufid)
	local attached_clients = vim.lsp.get_active_clients({ bufnr = bufid })
	if #attached_clients == 0 then
		return false
	end

	for _, client in ipairs(attached_clients) do
		if READY_CLIENTS[client.id] then
			return true
		end
	end
	return false
end

local function handle_progress(err, msg, info)
	-- See: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#progress

	local task = msg.token
	local val = msg.value

	if not task then
		-- Notification missing required token??
		return
	end

	local client = vim.lsp.get_client_by_id(info.client_id)
	if not client then
		return
	end

	local client_key = info.client_id
	if val.kind == 'begin' then
		if AMOUNT_IN_PROGRESS[client_key] then
			AMOUNT_IN_PROGRESS[client_key] = AMOUNT_IN_PROGRESS[client_key] + 1
		else
			READY_CLIENTS[client_key] = false
			AMOUNT_IN_PROGRESS[client_key] = 1

			if CLIENT_TIMER[client_key] then
				CLIENT_TIMER[client_key]:stop()
				CLIENT_TIMER[client_key]:close()
				CLIENT_TIMER[client_key] = nil
			end
		end
	elseif val.kind == 'end' then
		if AMOUNT_IN_PROGRESS[client_key] == nil then
			return
		end
		AMOUNT_IN_PROGRESS[client_key] = AMOUNT_IN_PROGRESS[client_key] - 1
		if AMOUNT_IN_PROGRESS[client_key] == 0 then
			if CLIENT_TIMER[client_key] then
				return -- There is already a timer, no need to create a new one
			end

			CLIENT_TIMER[client_key] = uv.new_timer()

			-- Wait 2 seconds until to see that the lsp isnt starting to a new progress
			CLIENT_TIMER[client_key]:start(2 * 1000, 0, function()
				if AMOUNT_IN_PROGRESS[client_key] == 0 then
					READY_CLIENTS[client_key] = true
				end
				CLIENT_TIMER[client_key]:stop()
				CLIENT_TIMER[client_key]:close()
				CLIENT_TIMER[client_key] = nil
			end)
		end
	end
end

function M.setup()
	if vim.lsp.handlers['$/progress'] then
		local old_handler = vim.lsp.handlers['$/progress']
		vim.lsp.handlers['$/progress'] = function(...)
			old_handler(...)
			handle_progress(...)
		end
	else
		vim.lsp.handlers['$/progress'] = handle_progress
	end
end

return M
