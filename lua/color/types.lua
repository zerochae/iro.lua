---@alias color.Mode "background"|"foreground"|"virtualtext"

---@class color.Options
---@field RGB? boolean
---@field RRGGBB? boolean
---@field names? boolean
---@field mode? color.Mode|color.Mode[]
---@field virtualtext? string
---@field editor_bg? string
---@field filetypes? string[]
---@field exclusions? string[]
---@field lsp? boolean

---@class color.Match
---@field col_start integer
---@field col_end integer
---@field rgb_hex string

---@class color.RGB
---@field r number
---@field g number
---@field b number

---@alias color.HighlightCache table<string, string>
---@alias color.ColorMap table<string, string>
---@alias color.AttachedMap table<integer, color.Options>
---@alias color.LspColorCache table<integer, table<integer, color.Match[]>>
---@alias color.TimerMap table<integer, uv.uv_timer_t>
---@alias color.AutocmdMap table<integer, integer[]>
