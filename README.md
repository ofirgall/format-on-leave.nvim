# format-on-leave.nvim
Autocmd on `BufLeave` for synchronous `vim.lsp.buf.format` with disable/enable commands.

Mainly for users who wants to use `auto save` but don't want to format the code every time nvim saves the code.


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
	pattern = { '*' },        -- Which files pattern to format
	formatting_options = nil, --Passed to `vim.lsp.buf.format` formatting_options
	filter = nil,             -- Passed to `vim.lsp.buf.format` filter
}
```

## Commands
* `FormatDisable`
* `FormatEnable`
