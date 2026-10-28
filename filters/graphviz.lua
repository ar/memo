-- Render dot fences as vector PDF images for memo's XeLaTeX pipeline.
-- memo removes dot-img on exit, unless --keep was requested.
function CodeBlock(block)
  if not block.classes:includes('dot') or FORMAT ~= 'latex' then
    return nil
  end

  local ok, pdf = pcall(pandoc.pipe, 'dot', {'-Tpdf'}, block.text)
  if not ok then
    local message = 'Graphviz could not render a dot fence. Install Graphviz '
      .. '(dot) and check the diagram syntax.\n' .. tostring(pdf)
    io.stderr:write('[ERROR] ' .. message .. '\n')
    error(message, 0)
  end

  local directory = 'dot-img'
  pandoc.system.make_directory(directory, true)
  local path = directory .. '/' .. pandoc.utils.sha1(block.text) .. '.pdf'
  local file = assert(io.open(path, 'wb'))
  assert(file:write(pdf))
  assert(file:close())

  local caption = block.attributes.caption or ''
  local attributes = {}
  for _, name in ipairs({'width', 'height'}) do
    attributes[name] = block.attributes[name]
  end
  local image = pandoc.Image(caption, path, caption ~= '' and 'fig:' or '',
    pandoc.Attr(block.identifier, {}, attributes))
  if caption ~= '' and pandoc.Figure then
    image.identifier = ''
    return pandoc.Figure({pandoc.Plain({image})},
      {pandoc.Plain({pandoc.Str(caption)})}, pandoc.Attr(block.identifier))
  end
  -- Pandoc before 3.0 uses standalone images with fig: titles for figures.
  return pandoc.Para({image})
end
