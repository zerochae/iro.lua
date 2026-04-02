---@alias iro.Mode "background"|"foreground"|"virtualtext"

---@class iro.Options
---@field RGB? boolean
---@field RRGGBB? boolean
---@field names? boolean
---@field mode? iro.Mode|iro.Mode[]
---@field virtualtext? string
---@field editor_bg? string
---@field filetypes? string[]
---@field exclusions? string[]
---@field css_fn? boolean
---@field lsp? boolean

---@class iro.Match
---@field col_start integer
---@field col_end integer
---@field rgb_hex string
---@field alpha? number
---@field virtualtext_only? boolean

---@class iro.RGB
---@field r number
---@field g number
---@field b number

---@alias iro.HighlightCache table<string, string>
---@alias iro.ColorMap table<string, string>
---@alias iro.AttachedMap table<integer, iro.Options>
---@alias iro.LspColorCache table<integer, table<integer, iro.Match[]>>
---@alias iro.TimerMap table<integer, uv.uv_timer_t>
---@alias iro.AutocmdMap table<integer, integer[]>
