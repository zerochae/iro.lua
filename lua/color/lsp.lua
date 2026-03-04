local M = {}

---@type table<integer, table<integer, color.Match[]>>
local cache = {}

---@type table<integer, uv_timer_t>
local timers = {}

---@type table<integer, integer[]>
local autocmd_ids = {}

local DEBOUNCE_MS = 200

---@param color { red: number, green: number, blue: number }
---@return string
local function color_to_hex(color)
  return string.format(
    "%02x%02x%02x",
    math.floor(color.red * 255 + 0.5),
    math.floor(color.green * 255 + 0.5),
    math.floor(color.blue * 255 + 0.5)
  )
end

---@param buf integer
---@return vim.lsp.Client[]
local function get_clients(buf)
  return vim.lsp.get_clients({ bufnr = buf, method = "textDocument/documentColor" })
end

---@param buf integer
---@param callback? fun()
function M.request(buf, callback)
  local clients = get_clients(buf)
  if #clients == 0 then
    cache[buf] = nil
    if callback then
      callback()
    end
    return
  end

  local params = { textDocument = vim.lsp.util.make_text_document_params(buf) }

  clients[1]:request("textDocument/documentColor", params, function(err, result)
    if err or not result then
      cache[buf] = nil
      if callback then
        callback()
      end
      return
    end

    ---@type table<integer, color.Match[]>
    local buf_colors = {}
    for _, item in ipairs(result) do
      local row = item.range.start.line
      local col_start = item.range.start.character + 1
      local col_end = item.range["end"].character
      local rgb_hex = color_to_hex(item.color)

      if not buf_colors[row] then
        buf_colors[row] = {}
      end
      table.insert(buf_colors[row], {
        col_start = col_start,
        col_end = col_end,
        rgb_hex = rgb_hex,
      })
    end

    cache[buf] = buf_colors
    if callback then
      callback()
    end
  end, buf)
end

---@param buf integer
---@param callback? fun()
local function debounced_request(buf, callback)
  if timers[buf] then
    timers[buf]:stop()
  else
    timers[buf] = vim.uv.new_timer()
  end

  timers[buf]:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    M.request(buf, callback)
  end))
end

---@param buf integer
---@param row integer
---@return color.Match[]
function M.get_colors(buf, row)
  if not cache[buf] then
    return {}
  end
  return cache[buf][row] or {}
end

---@param buf integer
---@param callback fun()
function M.attach(buf, callback)
  if autocmd_ids[buf] then
    return
  end

  local augroup = vim.api.nvim_create_augroup("color_lsp_" .. buf, { clear = true })

  local ids = {}

  ids[#ids + 1] = vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup,
    buffer = buf,
    callback = function()
      debounced_request(buf, callback)
    end,
  })

  ids[#ids + 1] = vim.api.nvim_create_autocmd("LspDetach", {
    group = augroup,
    buffer = buf,
    callback = function()
      cache[buf] = nil
      callback()
    end,
  })

  autocmd_ids[buf] = ids

  if #get_clients(buf) > 0 then
    debounced_request(buf, callback)
  end
end

---@param buf integer
function M.trigger(buf, callback)
  debounced_request(buf, callback)
end

---@param buf integer
function M.detach(buf)
  if autocmd_ids[buf] then
    vim.api.nvim_del_augroup_by_name("color_lsp_" .. buf)
    autocmd_ids[buf] = nil
  end

  if timers[buf] then
    timers[buf]:stop()
    timers[buf]:close()
    timers[buf] = nil
  end

  cache[buf] = nil
end

return M
