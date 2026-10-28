--- table-widths.lua — deterministic column widths for every table.
---
--- Pandoc renders a pipe table at natural width until any of its source
--- lines exceeds --columns (default 72); past that it switches to full
--- text width with relative column widths taken from the dash counts in
--- the separator row. Layout therefore depends on trailing spaces and
--- dash runs — invisible source formatting that any reflow silently
--- changes. This filter makes layout a property of content instead:
--- every table gets explicit column widths proportional to its longest
--- cell per column. Wrap a table in a fenced div `::: {.natural-width}`
--- to keep pandoc's default auto-width rendering.

local MIN_WIDTH = 0.06   -- floor so tiny columns (e.g. "Bit") stay readable
local CHARS_PER_LINE = 80 -- conservative body-width capacity in characters
local MAX_FLOOR = 0.35   -- one pathological unbreakable cell can't eat the page
local CODE_FACTOR = 1.0  -- monospace width relative to the body face; the +2 padding covers the rest

local function len(text)
  -- Count UTF-8 codepoints, not bytes, so accented text doesn't skew widths.
  local ok, n = pcall(function() return pandoc.text.len(text) end)
  return ok and n or #text
end

local function cell_text(cell)
  return pandoc.utils.stringify(pandoc.Blocks(cell.contents))
end

local function rows_max(rows, max, word)
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row.cells) do
      local text = cell_text(cell)
      local n = len(text)
      if n > (max[i] or 0) then max[i] = n end
      -- A code span is set in a wider monospace face and never wraps, so
      -- it counts as one word at roughly 1.3 proportional characters each.
      local code = 0
      pandoc.Div(cell.contents):walk({ Code = function(c)
        local cn = math.ceil(len(c.text) * CODE_FACTOR)
        if cn > code then code = cn end
      end })
      if code > (word[i] or 0) then word[i] = code end
      if code > max[i] then max[i] = code end
      -- Longest unbreakable run: a p-column wraps at spaces and after
      -- hyphens, but never inside a word or a number like 400,000.
      -- U+00A0 is a deliberate non-break; Lua's %s may match it, so hide it.
      for w in (text:gsub('\194\160', '_')):gmatch('[^%s%-]+') do
        local wn = len(w)
        if wn > (word[i] or 0) then word[i] = wn end
      end
    end
  end
end

local function Table(tbl)
  local ncols = #tbl.colspecs
  if ncols == 0 then return nil end

  local max, word = {}, {}
  rows_max(tbl.head.rows, max, word)
  for _, body in ipairs(tbl.bodies) do
    rows_max(body.body, max, word)
    rows_max(body.head, max, word)
  end
  rows_max(tbl.foot.rows, max, word)

  local total = 0
  for i = 1, ncols do
    max[i] = math.max(max[i] or 1, 1)
    total = total + max[i]
  end
  if total == 0 then return nil end

  -- Per-column floor: MIN_WIDTH, or the longest unbreakable word plus
  -- padding — a column narrower than its longest word overflows the rule.
  local floor, floor_sum = {}, 0
  for i = 1, ncols do
    floor[i] = math.min(
      math.max(MIN_WIDTH, ((word[i] or 1) + 2) / CHARS_PER_LINE),
      MAX_FLOOR)
    floor_sum = floor_sum + floor[i]
  end

  -- Proportional widths clamped to the floors, then fitted to exactly 1.0
  -- (full text width): scale only the slack above the floors, so no
  -- column is ever squeezed back under its longest word.
  local widths, sum = {}, 0
  for i = 1, ncols do
    widths[i] = math.max(max[i] / total, floor[i])
    sum = sum + widths[i]
  end
  if sum > 1 and floor_sum < 1 then
    local scale = (1 - floor_sum) / (sum - floor_sum)
    for i = 1, ncols do
      widths[i] = floor[i] + (widths[i] - floor[i]) * scale
    end
  else
    for i = 1, ncols do widths[i] = widths[i] / sum end
  end
  for i = 1, ncols do
    local align = tbl.colspecs[i][1]
    tbl.colspecs[i] = { align, widths[i] }
  end
  return tbl
end

--- Escape hatch: `::: {.natural-width}` restores pandoc's default
--- auto-width rendering for the tables it wraps. Divs are processed after
--- the tables inside them, so this undoes the assignment above.
local function Div(div)
  if not div.classes:includes('natural-width') then return nil end
  div.content = div.content:walk({
    Table = function(tbl)
      for i = 1, #tbl.colspecs do
        tbl.colspecs[i] = { tbl.colspecs[i][1], pandoc.ColWidthDefault }
      end
      return tbl
    end
  })
  return div
end

return { { Table = Table }, { Div = Div } }
