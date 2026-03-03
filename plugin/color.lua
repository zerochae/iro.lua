if vim.g.loaded_color then
  return
end
vim.g.loaded_color = true

vim.api.nvim_create_user_command("Color", function(args)
  local color = require("color")
  local sub = args.fargs[1]

  if not sub or sub == "toggle" then
    color.toggle()
  elseif sub == "attach" then
    color.attach()
  elseif sub == "detach" then
    color.detach()
  elseif sub == "reload" then
    color.reload()
  end
end, {
  nargs = "?",
  complete = function()
    return { "attach", "detach", "toggle", "reload" }
  end,
})
