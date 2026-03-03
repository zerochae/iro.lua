local M = {}

---@type color.Options
M.defaults = {
  RGB = true,
  RRGGBB = true,
  names = true,
  mode = "background",
  virtualtext = "██",
  filetypes = { "*" },
  exclusions = {},
}

---@type color.Options
M.options = {}

---@param opts? color.Options
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", {}, M.defaults, opts or {})
end

---@return color.Options
function M.get()
  return M.options
end

return M
