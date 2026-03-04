local parser = require("color.parser")
local highlight = require("color.highlight")
local lsp = require("color.lsp")

local M = {}

local ns = vim.api.nvim_create_namespace("color")
local augroup = vim.api.nvim_create_augroup("color_buffer", { clear = true })

---@type color.AttachedMap
local attached = {}

---@param mode color.Mode|color.Mode[]
---@return color.Mode[]
local function normalize_modes(mode)
  if type(mode) == "table" then
    return mode
  end
  return { mode or "background" }
end

---@param buf integer
---@param row integer
---@param options color.Options
local function highlight_line(buf, row, options)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
  if not line then
    return
  end
  local modes = normalize_modes(options.mode)
  local glyph = options.virtualtext or "██"
  local matches = parser.scan_line(line, options)

  if options.lsp then
    local lsp_colors = lsp.get_colors(buf, row)
    for _, lc in ipairs(lsp_colors) do
      local dominated = false
      for _, m in ipairs(matches) do
        if lc.col_start <= m.col_end and lc.col_end >= m.col_start then
          dominated = true
          break
        end
      end
      if not dominated then
        matches[#matches + 1] = lc
      end
    end
  end

  local line_len = #line
  for _, m in ipairs(matches) do
    local col_start = math.min(m.col_start - 1, line_len)
    local col_end = math.min(m.col_end, line_len)
    if col_start < col_end then
      for _, mode in ipairs(modes) do
        local hl_group = highlight.ensure(m.rgb_hex, mode)
        if mode == "virtualtext" then
          vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
            virt_text = { { glyph, hl_group } },
            virt_text_pos = "inline",
          })
        else
          vim.api.nvim_buf_set_extmark(buf, ns, row, col_start, {
            end_col = col_end,
            hl_group = hl_group,
          })
        end
      end
    end
  end
end

---@param buf integer
---@param min integer
---@param max integer
---@param options color.Options
local function highlight_range(buf, min, max, options)
  vim.api.nvim_buf_clear_namespace(buf, ns, min, max)
  for row = min, max - 1 do
    highlight_line(buf, row, options)
  end
end

---@param buf integer
---@param options color.Options
function M.attach(buf, options)
  if attached[buf] then
    return
  end
  attached[buf] = options

  local line_count = vim.api.nvim_buf_line_count(buf)
  highlight_range(buf, 0, line_count, options)

  local function lsp_refresh()
    if not attached[buf] or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    local min = vim.fn.line("w0") - 1
    local max = vim.fn.line("w$")
    highlight_range(buf, min, max, attached[buf])
  end

  if options.lsp then
    lsp.attach(buf, lsp_refresh)
  end

  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function(_, b)
      attached[b] = nil
      lsp.detach(b)
    end,
  })

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      if not attached[buf] then
        return
      end
      if options.lsp then
        lsp.trigger(buf, lsp_refresh)
      end
      if vim.fn.mode() == "i" then
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        highlight_line(buf, row, attached[buf])
      else
        local min = vim.fn.line("w0") - 1
        local max = vim.fn.line("w$")
        highlight_range(buf, min, max, attached[buf])
      end
    end,
  })

  vim.api.nvim_create_autocmd({ "WinScrolled", "BufEnter" }, {
    group = augroup,
    buffer = buf,
    callback = function()
      if not attached[buf] then
        return
      end
      local min = vim.fn.line("w0") - 1
      local max = vim.fn.line("w$")
      highlight_range(buf, min, max, attached[buf])
    end,
  })
end

---@param buf integer
function M.detach(buf)
  if not attached[buf] then
    return
  end
  attached[buf] = nil
  lsp.detach(buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  vim.api.nvim_clear_autocmds({ group = augroup, buffer = buf })
end

---@param buf integer
---@param options color.Options
function M.toggle(buf, options)
  if attached[buf] then
    M.detach(buf)
  else
    M.attach(buf, options)
  end
end

---@param buf? integer
---@param options color.Options
function M.reload(buf, options)
  if buf then
    if attached[buf] then
      attached[buf] = options
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      local line_count = vim.api.nvim_buf_line_count(buf)
      highlight_range(buf, 0, line_count, options)
    end
  else
    for b, _ in pairs(attached) do
      if vim.api.nvim_buf_is_valid(b) then
        attached[b] = options
        vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
        local line_count = vim.api.nvim_buf_line_count(b)
        highlight_range(b, 0, line_count, options)
      else
        attached[b] = nil
      end
    end
  end
end

---@param buf integer
---@return boolean
function M.is_attached(buf)
  return attached[buf] ~= nil
end

return M
