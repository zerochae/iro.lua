local config = require("iro.config")
local buffer = require("iro.buffer")
local highlight = require("iro.highlight")
local parser = require("iro.parser")

local M = {}

local augroup = vim.api.nvim_create_augroup("iro", { clear = true })

---@param buf integer
---@return boolean
local function should_attach(buf)
  local bt = vim.bo[buf].buftype
  if bt ~= "" then
    return false
  end

  local opts = config.get()
  local ft = vim.bo[buf].filetype

  for _, exc in ipairs(opts.exclusions or {}) do
    if ft == exc then
      return false
    end
  end

  local filetypes = opts.filetypes or { "*" }
  for _, f in ipairs(filetypes) do
    if f == "*" or f == ft then
      return true
    end
  end

  return false
end

---@param opts? iro.Options
function M.setup(opts)
  config.setup(opts)
  highlight.set_editor_bg(config.get().editor_bg)

  vim.api.nvim_clear_autocmds({ group = augroup })

  vim.api.nvim_create_autocmd("FileType", {
    group = augroup,
    callback = function(ev)
      if should_attach(ev.buf) then
        buffer.attach(ev.buf, config.get())
      end
    end,
  })

  vim.api.nvim_create_autocmd("ColorScheme", {
    group = augroup,
    callback = function()
      highlight.clear_cache()
      parser.clear_cache()
      buffer.reload(nil, config.get())
    end,
  })

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and should_attach(buf) then
      buffer.attach(buf, config.get())
    end
  end
end

---@param buf? integer
function M.attach(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  buffer.attach(buf, config.get())
end

---@param buf? integer
function M.detach(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  buffer.detach(buf)
end

---@param buf? integer
function M.toggle(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  buffer.toggle(buf, config.get())
end

---@param buf? integer
function M.reload(buf)
  buffer.reload(buf, config.get())
end

return M
