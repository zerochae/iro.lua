# color.lua - Implementation Plan

## Context

nvim-colorizer.lua와 동일한 기능의 color highlighting plugin을 **Pure Lua**로 구현한다.
FFI 없이 `string.find` 패턴 매칭 + Lua 테이블 기반으로 단순하고 읽기 쉬운 코드를 지향한다.

## File Structure

```
color.lua/
├── plugin/color.lua              # Entry point (loaded guard, user commands)
├── lua/color/init.lua            # Main module (setup, attach/detach/toggle/reload)
├── lua/color/config.lua          # Config (defaults + vim.tbl_deep_extend)
├── lua/color/types.lua           # LuaLS type annotations
├── lua/color/parser.lua          # Hex parser + color name parser (Pure Lua)
├── lua/color/highlight.lua       # Highlight group creation + caching
├── lua/color/buffer.lua          # Buffer attach/detach, incremental update
├── .luarc.json
├── .stylua.toml
├── selene.toml
└── LICENSE
```

## nvim-colorizer.lua와의 차이점

| | nvim-colorizer.lua | color.lua |
|---|---|---|
| Trie | FFI C struct (malloc/free) | Lua 테이블 해시맵 |
| Byte 분류 | FFI 256-byte 룩업 + 비트 연산 | `string.find` 패턴 매칭 |
| Hex 파싱 | 바이트 루프 + bit.lshift/bor | `string.find("()#(%x+)()")` |
| 색상 이름 매칭 | Trie longest_prefix | 정렬된 테이블 순회 + `string.sub` 비교 |
| 의존성 | LuaJIT FFI, bit 라이브러리 | 순수 Lua + vim API |

## Module Design

### 1. `lua/color/parser.lua` - Core Parsing (Pure Lua)

**Hex 파싱** - `string.find` 패턴 사용:

```lua
local HEX6 = "#(%x%x%x%x%x%x)"
local HEX3 = "#(%x%x%x)"

function M.find_hex(line, init)
  local s6, e6, hex6 = line:find(HEX6, init)
  if s6 then return s6, e6, hex6 end
  local s3, e3, hex3 = line:find(HEX3, init)
  if s3 then return s3, e3, hex3 end
end
```

단어 경계 검사: 매칭 위치 앞뒤가 `%w`이면 스킵 (식별자 내부 매칭 방지)

**색상 이름 매칭** - Lua 테이블 기반:

```lua
local COLOR_MAP = nil  -- lazy init

local function init_colors()
  COLOR_MAP = {}
  for name, rgb in pairs(vim.api.nvim_get_color_map()) do
    COLOR_MAP[name:lower()] = string.format("%06x", rgb)
  end
end
```

라인 스캔 시 `%a+` 패턴으로 단어를 추출하고, `COLOR_MAP[word:lower()]`로 룩업.
O(1) 해시 테이블 조회라 Trie와 실질적 성능 차이 없음.

**통합 스캐너** - 라인 단위 매칭:

```lua
function M.scan_line(line, options)
  local matches = {}

  if options.RGB or options.RRGGBB then
    -- string.find 루프로 hex 매칭 수집
  end

  if options.names then
    -- %a+ 패턴으로 단어 추출 후 COLOR_MAP 룩업
  end

  return matches  -- { { col_start, col_end, rgb_hex }, ... }
end
```

반환값을 matches 배열로 수집하여, buffer 모듈에서 일괄 하이라이트 적용.

### 2. `lua/color/highlight.lua` - Highlight Creation

```lua
local CACHE = {}

function M.ensure(rgb_hex, mode)
  local key = mode .. "_" .. rgb_hex
  if CACHE[key] then return CACHE[key] end

  local name = "color_" .. key
  local r = tonumber(rgb_hex:sub(1, 2), 16)
  local g = tonumber(rgb_hex:sub(3, 4), 16)
  local b = tonumber(rgb_hex:sub(5, 6), 16)

  if mode == "background" then
    local luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
    local fg = luminance > 0.5 and "#000000" or "#ffffff"
    vim.api.nvim_set_hl(0, name, { fg = fg, bg = "#" .. rgb_hex })
  else
    vim.api.nvim_set_hl(0, name, { fg = "#" .. rgb_hex })
  end

  CACHE[key] = name
  return name
end

function M.clear_cache()
  CACHE = {}
end
```

### 3. `lua/color/buffer.lua` - Buffer Lifecycle

```lua
local ns = vim.api.nvim_create_namespace("color")
local attached = {}  -- { [bufnr] = options }
```

- `highlight_lines(buf, lines, line_start, options)`:
  - `parser.scan_line()`으로 매칭 수집
  - `nvim_buf_set_extmark`로 하이라이트 적용

- `attach(buf, options)`:
  - 전체 라인 하이라이팅 (초기)
  - `nvim_buf_attach`로 `on_lines` 콜백 등록 (incremental)

- `detach(buf)`: namespace clear + attached 제거
- `toggle(buf, options)`: attached 여부에 따라 전환
- `reload_all()`: 모든 attached 버퍼 재하이라이팅

### 4. `lua/color/config.lua` - Configuration

lemon.nvim 패턴 준수: `M.defaults` / `M.options` / `M.setup(opts)` / `M.get()`

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `RGB` | boolean | `true` | #RGB (3-digit) hex |
| `RRGGBB` | boolean | `true` | #RRGGBB (6-digit) hex |
| `names` | boolean | `true` | Named colors (Red, Blue, ...) |
| `mode` | string | `"background"` | "background" or "foreground" |
| `filetypes` | table | `{"*"}` | Auto-attach filetypes |
| `exclusions` | table | `{}` | Excluded filetypes |

### 5. `lua/color/init.lua` - Main Module

- `setup(opts)`: config 초기화 + FileType autocmd + ColorScheme autocmd
- `attach(buf?)`, `detach(buf?)`, `toggle(buf?)`, `reload(buf?)`

### 6. `plugin/color.lua` - Entry Point

- `vim.g.loaded_color` guard
- `:Color [attach|detach|toggle|reload]` user command

## User Commands

| Command | Description |
|---------|-------------|
| `:Color` | Toggle current buffer |
| `:Color attach` | Attach to current buffer |
| `:Color detach` | Detach from current buffer |
| `:Color toggle` | Toggle current buffer |
| `:Color reload` | Reload highlights |

## Public API

```lua
require("color").setup({
  RGB = true,
  RRGGBB = true,
  names = true,
  mode = "background",
  filetypes = { "*" },
  exclusions = {},
})

require("color").attach(buf)
require("color").detach(buf)
require("color").toggle(buf)
require("color").reload(buf)
```

## Implementation Order

1. `.luarc.json`, `.stylua.toml`, `selene.toml`, `LICENSE`
2. `lua/color/types.lua`
3. `lua/color/config.lua`
4. `lua/color/parser.lua` (Pure Lua, no dependencies)
5. `lua/color/highlight.lua`
6. `lua/color/buffer.lua` (depends on parser, highlight)
7. `lua/color/init.lua` (depends on config, buffer)
8. `plugin/color.lua` (depends on init)

## Key Design Decisions

- **Pure Lua**: FFI 없이 `string.find` + Lua 테이블로 구현. 단순하고 디버깅 용이
- **해시맵 색상 룩업**: Trie 대신 Lua 테이블 O(1) 조회. 실사용 성능 동등
- **extmark 사용**: `nvim_buf_add_highlight` 대신 `nvim_buf_set_extmark` (priority 지원)
- **nvim_set_hl 사용**: modern Neovim API
- **lazy 색상 초기화**: 첫 사용 시 `nvim_get_color_map()` 로드
- **ColorScheme autocmd**: colorscheme 변경 시 highlight cache clear + 재하이라이팅

## Verification

1. Neovim에서 `require("color").setup()` 호출
2. 임의 파일에서 `#ff0000`, `#0f0`, `Red`, `DarkBlue` 등 입력
3. background/foreground 모드 전환 확인
4. `:Color detach` / `:Color attach` 동작 확인
5. 텍스트 편집 시 incremental update 확인
6. colorscheme 변경 후 하이라이트 유지 확인
