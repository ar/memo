-- Used only by custom_magazine: promote a leading H1 to the article title,
-- retaining its identifier as a link target. Preserve explicit YAML titles.
function Pandoc(doc)
  if not doc.meta['memo-magazine'] then return nil end
  local first = doc.blocks[1]
  if not doc.meta.title and first and first.t == 'Header' and first.level == 1 then
    doc.meta.title = pandoc.MetaInlines(first.content)
    doc.blocks:remove(1)
    if first.identifier ~= '' then
      doc.blocks:insert(1, pandoc.Div({}, pandoc.Attr(first.identifier)))
    end
    -- The remaining H2s become sections, H3s become subsections, etc.
    doc = doc:walk({Header = function(h) h.level = math.max(1, h.level - 1); return h end})
  end
  return doc:walk({HorizontalRule = function()
    return pandoc.RawBlock('latex', '\\magazineseparator{}')
  end})
end
