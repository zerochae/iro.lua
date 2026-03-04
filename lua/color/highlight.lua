local M = {}

---@type color.HighlightCache
local CACHE = {}

local CONTRAST_THRESHOLD = 0.3

---@type string?
local user_editor_bg = nil

---@type color.RGB?
local editor_bg = nil

---@param hex string
---@return color.RGB
local function parse_hex(hex)
  hex = hex:gsub("^#", "")
  return {
    r = tonumber(hex:sub(1, 2), 16) or 0,
    g = tonumber(hex:sub(3, 4), 16) or 0,
    b = tonumber(hex:sub(5, 6), 16) or 0,
  }
end

local function get_editor_bg()
  if editor_bg then
    return editor_bg
  end
  if user_editor_bg then
    editor_bg = parse_hex(user_editor_bg)
    return editor_bg
  end
  local normal = vim.api.nvim_get_hl(0, { name = "Normal" })
  if normal.bg then
    editor_bg = parse_hex(string.format("%06x", normal.bg))
  end
  return editor_bg
end

local function relative_luminance(r, g, b)
  local rs = r / 255
  local gs = g / 255
  local bs = b / 255
  rs = rs <= 0.03928 and rs / 12.92 or ((rs + 0.055) / 1.055) ^ 2.4
  gs = gs <= 0.03928 and gs / 12.92 or ((gs + 0.055) / 1.055) ^ 2.4
  bs = bs <= 0.03928 and bs / 12.92 or ((bs + 0.055) / 1.055) ^ 2.4
  return 0.2126 * rs + 0.7152 * gs + 0.0722 * bs
end

local function contrast_ratio(r1, g1, b1, r2, g2, b2)
  local l1 = relative_luminance(r1, g1, b1)
  local l2 = relative_luminance(r2, g2, b2)
  local lighter = math.max(l1, l2)
  local darker = math.min(l1, l2)
  return (lighter + 0.05) / (darker + 0.05)
end

local function is_low_contrast(r, g, b)
  local bg = get_editor_bg()
  if not bg then
    return false
  end
  return contrast_ratio(r, g, b, bg.r, bg.g, bg.b) < 1 + CONTRAST_THRESHOLD
end

local GAMMA = 1.5

local function lighten(r, g, b)
  return math.floor(255 * (r / 255) ^ (1 / GAMMA)),
    math.floor(255 * (g / 255) ^ (1 / GAMMA)),
    math.floor(255 * (b / 255) ^ (1 / GAMMA))
end

---@param rgb_hex string
---@param mode color.Mode
---@return string hl_group
function M.ensure(rgb_hex, mode)
  local key = mode .. "_" .. rgb_hex
  if CACHE[key] then
    return CACHE[key]
  end

  local name = "color_" .. key
  local r = tonumber(rgb_hex:sub(1, 2), 16) or 0
  local g = tonumber(rgb_hex:sub(3, 4), 16) or 0
  local b = tonumber(rgb_hex:sub(5, 6), 16) or 0
  local low = is_low_contrast(r, g, b)

  if mode == "background" then
    local bg_hex, fg
    if low then
      local lr, lg, lb = lighten(r, g, b)
      bg_hex = string.format("#%02x%02x%02x", lr, lg, lb)
      fg = "#000000"
    else
      bg_hex = "#" .. rgb_hex
      local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
      fg = luminance > 0.5 and "#000000" or "#ffffff"
    end
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = bg_hex })
  else
    local color = "#" .. rgb_hex
    if low then
      local lr, lg, lb = lighten(r, g, b)
      color = string.format("#%02x%02x%02x", lr, lg, lb)
    end
    vim.api.nvim_set_hl(0, name, { fg = color })
  end

  CACHE[key] = name
  return name
end

---@param bg? string
function M.set_editor_bg(bg)
  user_editor_bg = bg
end

function M.clear_cache()
  CACHE = {}
  editor_bg = nil
end

return M
