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

---@class color.Match
---@field col_start integer
---@field col_end integer
---@field rgb_hex string
