local lsp = require("iro.lsp")

describe("lsp", function()
  it("returns empty for unknown buffer", function()
    assert.are.same({}, lsp.get_colors(9999, 0))
  end)

  it("returns empty for unknown row", function()
    assert.are.same({}, lsp.get_colors(9999, 5))
  end)

  it("detach on unattached buffer is safe", function()
    assert.has_no.error(function()
      lsp.detach(9999)
    end)
  end)
end)
