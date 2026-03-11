local highlight = require("iro.highlight")

local M = {}

---@param item table
---@return string?
local function extract_color(item)
  if type(item) ~= "table" then
    return nil
  end

  local doc = item.documentation
  if type(doc) == "table" then
    doc = doc.value
  end
  if type(doc) == "string" then
    local hex = doc:match("#(%x%x%x%x%x%x)")
    if hex then
      return hex:lower()
    end
  end

  local detail = item.detail
  if type(detail) == "string" then
    local hex = detail:match("#(%x%x%x%x%x%x)")
    if hex then
      return hex:lower()
    end
  end

  return nil
end

function M.kind_icon(opts)
  opts = opts or {}
  local default_icon = opts.icon or "󱓻"
  local fallback = opts.fallback

  return {
    text = function(ctx)
      if ctx.kind == "Color" then
        local rgb = extract_color(ctx.item)
        if rgb then
          return default_icon .. ctx.icon_gap
        end
      end
      if fallback and fallback.text then
        return fallback.text(ctx)
      end
      return ctx.kind_icon .. ctx.icon_gap
    end,
    highlight = function(ctx)
      if ctx.kind == "Color" then
        local rgb = extract_color(ctx.item)
        if rgb then
          return highlight.ensure(rgb, "virtualtext")
        end
      end
      if fallback and fallback.highlight then
        return fallback.highlight(ctx)
      end
      return ctx.kind_hl
    end,
  }
end

---@param item table
---@return string?
function M.get_hl(item)
  local rgb = extract_color(item)
  if rgb then
    return highlight.ensure(rgb, "virtualtext")
  end
  return nil
end

return M
