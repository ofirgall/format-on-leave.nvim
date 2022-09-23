# format-on-leave.nvim
Autocmd on `BufLeave` for synchronous `vim.lsp.buf.format` with disable/enable commands


## Installation
```lua
use 'ofirgall/format-on-leave.nvim'
```

### Usage
```lua
-- Leave empty for default values
require('format-on-leave').setup {
}

-- Or setup with custom parameters
require('fomrat-on-leave').setup {
	save_after_format = true, -- Save after the format
	events = { 'BufLeave' },  -- When to trigger lsp format
	pattern = { '*' },        -- Which files pattern to fomrat
	formatting_options = nil, --Passed to `vim.lsp.buf.format` formatting_options
	filter = nil,             -- Passed to `vim.lsp.buf.format` filter
}
```

## Commands
* `FormatDisable`
* `FormatEnable`
