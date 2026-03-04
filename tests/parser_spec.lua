local parser = require("color.parser")

local RRGGBB = { RRGGBB = true }
local RGB = { RGB = true }
local NAMES = { names = true }
local ALL = { RRGGBB = true, RGB = true, names = true }

describe("parser", function()
  describe("RRGGBB", function()
    it("matches single hex color", function()
      local m = parser.scan_line("color: #ff0000;", RRGGBB)
      assert.are.equal(1, #m)
      assert.are.equal("ff0000", m[1].rgb_hex)
      assert.are.equal(8, m[1].col_start)
      assert.are.equal(14, m[1].col_end)
    end)

    it("matches multiple hex colors", function()
      local m = parser.scan_line("#aabbcc foo #112233", RRGGBB)
      assert.are.equal(2, #m)
      assert.are.equal("aabbcc", m[1].rgb_hex)
      assert.are.equal("112233", m[2].rgb_hex)
    end)

    it("returns empty on no match", function()
      local m = parser.scan_line("no color here", RRGGBB)
      assert.are.equal(0, #m)
    end)

    it("rejects when preceded by alphanumeric", function()
      local m = parser.scan_line("0x#ff0000", RRGGBB)
      assert.are.equal(0, #m)
    end)

    it("returns empty when disabled", function()
      local m = parser.scan_line("#ff0000", { RRGGBB = false })
      assert.are.equal(0, #m)
    end)

    it("matches inside brackets", function()
      local m = parser.scan_line('className="text-[#a4a9b2]"', RRGGBB)
      assert.are.equal(1, #m)
      assert.are.equal("a4a9b2", m[1].rgb_hex)
    end)

    it("lowercases hex", function()
      local m = parser.scan_line("#AABBCC", RRGGBB)
      assert.are.equal("aabbcc", m[1].rgb_hex)
    end)
  end)

  describe("RGB", function()
    it("matches and expands short hex", function()
      local m = parser.scan_line("#f0a", RGB)
      assert.are.equal(1, #m)
      assert.are.equal("ff00aa", m[1].rgb_hex)
    end)

    it("rejects pure digits", function()
      local m = parser.scan_line("#123", RGB)
      assert.are.equal(0, #m)
    end)

    it("coexists with RRGGBB", function()
      local m = parser.scan_line("#aabbcc #f0a", ALL)
      assert.are.equal(2, #m)
    end)
  end)

  describe("named colors", function()
    it("matches color name in string", function()
      local m = parser.scan_line('color = "red"', NAMES)
      assert.are.equal(1, #m)
      assert.are.equal(6, #m[1].rgb_hex)
    end)

    it("rejects outside string", function()
      local m = parser.scan_line("local red = 1", NAMES)
      assert.are.equal(0, #m)
    end)

    it("rejects with dot prefix", function()
      local m = parser.scan_line('"colors.blue"', NAMES)
      assert.are.equal(0, #m)
    end)

    it("rejects with dot suffix", function()
      local m = parser.scan_line('"blue.500"', NAMES)
      assert.are.equal(0, #m)
    end)

    it("rejects with dash", function()
      local m = parser.scan_line('"text-red"', NAMES)
      assert.are.equal(0, #m)
    end)

    it("rejects with underscore", function()
      local m = parser.scan_line('"bg_red"', NAMES)
      assert.are.equal(0, #m)
    end)

    it("matches standalone name in single quotes", function()
      local m = parser.scan_line("color = 'green'", NAMES)
      assert.are.equal(1, #m)
    end)

    it("matches in backtick string", function()
      local m = parser.scan_line("`red`", NAMES)
      assert.are.equal(1, #m)
    end)

    it("matches multiple names in one line", function()
      local m = parser.scan_line('"red" and "blue"', NAMES)
      assert.are.equal(2, #m)
    end)
  end)

  describe("edge cases", function()
    it("empty line returns empty", function()
      local m = parser.scan_line("", ALL)
      assert.are.equal(0, #m)
    end)

    it("only whitespace returns empty", function()
      local m = parser.scan_line("   ", ALL)
      assert.are.equal(0, #m)
    end)

    it("consecutive hex colors without space matches first only", function()
      local m = parser.scan_line("#aabbcc#112233", RRGGBB)
      assert.are.equal(1, #m)
      assert.are.equal("aabbcc", m[1].rgb_hex)
    end)

    it("hex followed by extra hex digit is rejected", function()
      local m = parser.scan_line("#aabbccd", RRGGBB)
      assert.are.equal(0, #m)
    end)

    it("RGB dominated by RRGGBB in same position", function()
      local m = parser.scan_line("#aabbcc", ALL)
      assert.are.equal(1, #m)
      assert.are.equal("aabbcc", m[1].rgb_hex)
    end)

    it("all options disabled returns empty", function()
      local m = parser.scan_line('#ff0000 "red" #f0a', { RRGGBB = false, RGB = false, names = false })
      assert.are.equal(0, #m)
    end)

    it("hex at start of line", function()
      local m = parser.scan_line("#ff0000 text", RRGGBB)
      assert.are.equal(1, #m)
      assert.are.equal(1, m[1].col_start)
    end)

    it("hex at end of line", function()
      local m = parser.scan_line("text #ff0000", RRGGBB)
      assert.are.equal(1, #m)
      assert.are.equal("ff0000", m[1].rgb_hex)
    end)

    it("mixed RRGGBB, RGB, and names", function()
      local m = parser.scan_line('#aabbcc #f0a "red"', ALL)
      assert.are.equal(3, #m)
    end)
  end)
end)
