--- twocolumn-tables.lua — two-column-safe tables.
---
--- Pandoc's LaTeX writer renders every table as a longtable, and
--- longtable refuses to run in twocolumn mode ("longtable not in
--- 1-column mode"), so any memo with a table fails the `double`
--- layout. When the `twocolumn` metadata flag is set (bin/memo sets it
--- for the `double` layout), rewrite each table's LaTeX into a plain
--- tabular inside a table* float, which spans both columns. Runs after
--- table-widths.lua (data-dir filters load in name order), so explicit
--- column widths are preserved.
---
--- ponytail: LaTeX cannot place a table* on the page where it appears —
--- it lands at the top of the NEXT page (or a trailing float page when
--- the document ends first). Live with it; stfloats if it ever hurts.

local function to_tabular(tbl)
  local latex = pandoc.write(pandoc.Pandoc({ tbl }), 'latex')
  latex = latex
    :gsub('\\begin{longtable}%[[^%]]*%]',
          '\\begin{table*}[!t]\n\\centering\n\\begin{tabular}')
    -- longtable renders the foot block at the end; flattened in place it
    -- would sit above the body, so move it there first.
    :gsub('\\endhead\n(.-)\\endlastfoot\n(.*)\\end{longtable}',
          '\\endhead\n%2%1\\end{longtable}')
    -- ponytail: naive marker strip — a table WITH a caption would keep a
    -- duplicated header row; teach this about \caption if we ever add one.
    :gsub('\\endfirsthead\n', '')
    :gsub('\\endhead\n', '')
    :gsub('\\endfoot\n', '')
    :gsub('\\endlastfoot\n', '')
    :gsub('\\end{longtable}', '\\end{tabular}\n\\end{table*}')
  return pandoc.RawBlock('latex', latex)
end

function Pandoc(doc)
  if not doc.meta.twocolumn then return nil end
  local found = false
  doc = doc:walk({ Table = function(t) found = true; return to_tabular(t) end })
  -- The raw blocks hide the tables from the writer, which would drop the
  -- table preamble (booktabs, array, calc); force it back on.
  if found then doc.meta.tables = true end
  return doc
end
