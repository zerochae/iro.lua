local M = {}

---@type iro.Options
M.defaults = {
  RGB = true,
  RRGGBB = true,
  names = true,
  mode = "background",
  virtualtext = "██",
  filetypes = { "*" },
  exclusions = {},
  lsp = true,
}

---@type iro.Options
M.options = {}

---@param opts? iro.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

---@return iro.Options
function M.get()
  return M.options
end

return M
