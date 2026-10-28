-- Pandoc 3 uses Figure nodes instead of standalone images titled "fig:".
-- Older external filters, including mermaid-filter, still emit that form.
function Para(block)
  if not pandoc.Figure or #block.content ~= 1 then return nil end
  local image = block.content[1]
  if image.t ~= 'Image' or not image.title:match('^fig:') then return nil end

  local identifier = image.identifier
  image.identifier = ''
  image.title = image.title:sub(5)
  return pandoc.Figure({pandoc.Plain({image})},
    {pandoc.Plain(image.caption)}, pandoc.Attr(identifier))
end
