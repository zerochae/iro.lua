if vim.g.loaded_iro then
  return
end
vim.g.loaded_iro = true

vim.api.nvim_create_user_command("Iro", function(args)
  local iro = require("iro")
  local sub = args.fargs[1]

  if not sub or sub == "toggle" then
    iro.toggle()
  elseif sub == "attach" then
    iro.attach()
  elseif sub == "detach" then
    iro.detach()
  elseif sub == "reload" then
    iro.reload()
  end
end, {
  nargs = "?",
  complete = function()
    return { "attach", "detach", "toggle", "reload" }
  end,
})
