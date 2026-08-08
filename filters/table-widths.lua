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

local function cell_len(cell)
  local text = pandoc.utils.stringify(pandoc.Blocks(cell.contents))
  -- Count UTF-8 codepoints, not bytes, so accented text doesn't skew widths.
  local ok, n = pcall(function() return pandoc.text.len(text) end)
  return ok and n or #text
end

local function rows_max(rows, max)
  for _, row in ipairs(rows) do
    for i, cell in ipairs(row.cells) do
      local n = cell_len(cell)
      if n > (max[i] or 0) then max[i] = n end
    end
  end
end

local function Table(tbl)
  local ncols = #tbl.colspecs
  if ncols == 0 then return nil end

  local max = {}
  rows_max(tbl.head.rows, max)
  for _, body in ipairs(tbl.bodies) do
    rows_max(body.body, max)
    rows_max(body.head, max)
  end
  rows_max(tbl.foot.rows, max)

  local total = 0
  for i = 1, ncols do
    max[i] = math.max(max[i] or 1, 1)
    total = total + max[i]
  end
  if total == 0 then return nil end

  -- Proportional widths, clamped to the floor, then renormalized to 1.0
  -- (full text width) so the sum is exact.
  local widths, sum = {}, 0
  for i = 1, ncols do
    widths[i] = math.max(max[i] / total, MIN_WIDTH)
    sum = sum + widths[i]
  end
  for i = 1, ncols do
    local align = tbl.colspecs[i][1]
    tbl.colspecs[i] = { align, widths[i] / sum }
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
