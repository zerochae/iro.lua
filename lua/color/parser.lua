local M = {}

local HEX6 = "#(%x%x%x%x%x%x)"
local HEX3 = "#(%x%x%x)"
local WORD = "()(%a+)()"

---@type color.ColorMap?
local COLOR_MAP = nil

local function init_colors()
  COLOR_MAP = {}
  for name, rgb in pairs(vim.api.nvim_get_color_map()) do
    COLOR_MAP[name:lower()] = string.format("%06x", rgb)
  end
end

---@param line string
---@param init integer
---@return integer?, integer?, string?
local function find_hex6(line, init)
  local s, e, hex = line:find(HEX6, init)
  if not s then
    return nil, nil, nil
  end
  local before = s > 1 and line:sub(s - 1, s - 1) or ""
  local after = e < #line and line:sub(e + 1, e + 1) or ""
  if before:find("%w") or after:find("%x") then
    return find_hex6(line, e + 1)
  end
  return s, e, hex
end

---@param line string
---@param init integer
---@return integer?, integer?, string?
local function find_hex3(line, init)
  local s, e, hex = line:find(HEX3, init)
  if not s then
    return nil, nil, nil
  end
  local before = s > 1 and line:sub(s - 1, s - 1) or ""
  local after = e < #line and line:sub(e + 1, e + 1) or ""
  if before:find("%w") or after:find("%x") then
    return find_hex3(line, e + 1)
  end
  if hex:find("^%d+$") then
    return find_hex3(line, e + 1)
  end
  return s, e, hex
end

---@param hex3 string
---@return string
local function expand_hex3(hex3)
  local r, g, b = hex3:sub(1, 1), hex3:sub(2, 2), hex3:sub(3, 3)
  return r .. r .. g .. g .. b .. b
end

---@param line string
---@return {[1]: integer, [2]: integer}[]
local function find_string_regions(line)
  local regions = {}
  local i = 1
  while i <= #line do
    local b = line:byte(i)
    if b == 34 or b == 39 or b == 96 then
      local quote = b
      local start = i
      i = i + 1
      while i <= #line and line:byte(i) ~= quote do
        if line:byte(i) == 92 then
          i = i + 1
        end
        i = i + 1
      end
      if i <= #line then
        regions[#regions + 1] = { start + 1, i - 1 }
      end
    end
    i = i + 1
  end
  return regions
end

---@param pos integer
---@param regions {[1]: integer, [2]: integer}[]
---@return boolean
local function in_string(pos, regions)
  for _, r in ipairs(regions) do
    if pos >= r[1] and pos <= r[2] then
      return true
    end
  end
  return false
end

---@param line string
---@param options color.Options
---@return color.Match[]
function M.scan_line(line, options)
  local matches = {}

  if options.RRGGBB then
    local init = 1
    while init <= #line do
      local s, e, hex = find_hex6(line, init)
      if not s or not e or not hex then
        break
      end
      matches[#matches + 1] = { col_start = s, col_end = e, rgb_hex = hex:lower() }
      init = e + 1
    end
  end

  if options.RGB then
    local init = 1
    while init <= #line do
      local s, e, hex = find_hex3(line, init)
      if not s or not e or not hex then
        break
      end
      local dominated = false
      for _, m in ipairs(matches) do
        if s >= m.col_start and e <= m.col_end then
          dominated = true
          break
        end
      end
      if not dominated then
        matches[#matches + 1] = { col_start = s, col_end = e, rgb_hex = expand_hex3(hex:lower()) }
      end
      init = e + 1
    end
  end

  if options.names then
    if not COLOR_MAP then
      init_colors()
    end
    ---@cast COLOR_MAP color.ColorMap
    local regions = find_string_regions(line)
    local init = 1
    while init <= #line do
      local ws, word, we = line:match(WORD, init)
      if not ws then
        break
      end
      ---@cast ws integer
      ---@cast we integer
      ---@cast word string
      local rgb = COLOR_MAP[word:lower()]
      if rgb and in_string(ws, regions) then
        local before = ws > 1 and line:byte(ws - 1) or 0
        local after = we <= #line and line:byte(we) or 0
        if before ~= 45 and before ~= 95 and before ~= 46 and after ~= 45 and after ~= 95 and after ~= 46 then
          matches[#matches + 1] = { col_start = ws, col_end = we - 1, rgb_hex = rgb }
        end
      end
      init = we
    end
  end

  return matches
end

function M.clear_cache()
  COLOR_MAP = nil
end

return M
