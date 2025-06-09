local lpeg = lpeg or require'lpeg'
local pdfscanner = require'show-pdf-tags_luapdfscanner'
local utf16be_to_utf8 = require'show-pdf-tags_decode'.utf16be_to_utf8
local text_string_to_utf8 = require'show-pdf-tags_decode'.text_string_to_utf8
local winansi_to_utf16be = require'show-pdf-tags_decode'.winansi_to_utf16be

local lookup = {}

local cmap_operators = {
  beginbfrange = function(scanner, ctx)
    assert(not ctx.mode)
    ctx.mode = 'bfrange'
    ctx.count = scanner:popnumber()
  end,
  endbfrange = function(scanner, ctx)
    assert(ctx.mode == 'bfrange')
    ctx.mode = nil
    for i=1, ctx.count do
      local target = scanner:popstring() or scanner:poparray()
      local last = scanner:popstring()
      local first = scanner:popstring()
      if first:sub(1, -2) == last:sub(1, -2) then
        local in_prefix = first:sub(1, -2)
        ctx.pattern = ctx.pattern + in_prefix * lpeg.R(first:sub(-1) .. last:sub(-1))
        local in_suffix_begin = first:byte(-1)
        local in_suffix_end = last:byte(-1)
        if type(target) == 'string' then
          local out_prefix = target:sub(1, -2)
          local out_suffix = target:byte(-1)
          for i = 0, in_suffix_end - in_suffix_begin do
            ctx.mapping[in_prefix .. string.char(in_suffix_begin + i)] = out_prefix .. string.char(out_suffix + i)
          end
        else
          for i = 0, in_suffix_end - in_suffix_begin do
            ctx.mapping[in_prefix .. string.char(in_suffix_begin + i)] = assert(assert(target[i+1])[2])
          end
        end
      else
        ctx.warnings[#ctx.warnings + 1] = "WARNING: Ignoring invalid ToUnicode mapping"
      end
    end
  end,
  beginbfchar = function(scanner, ctx)
    assert(not ctx.mode)
    ctx.mode = 'bfchar'
    ctx.count = scanner:popnumber()
  end,
  endbfchar = function(scanner, ctx)
    assert(ctx.mode == 'bfchar')
    ctx.mode = nil
    for i=1, ctx.count do
      local mapped = scanner:popstring()
      local char = scanner:popstring()
      ctx.mapping[char] = mapped
      ctx.pattern = ctx.pattern + char
    end
  end,
  endcmap = function(scanner, ctx)
    scanner:done()
  end,
}

local function parse_cmap(stream)
  local ctx = {
    pattern = lpeg.P(false), -- Maybe use 1 instead to passthough everything else
    mapping = {},
    warnings = {},
  }
  pdfscanner.scan(stream, cmap_operators, ctx)
  return lpeg.Cs((ctx.pattern/ctx.mapping)^0) * -1, ctx.warnings
end

local function print_string(ctx, str, font)
  if font.cmap then
    str = font.cmap:match(str)
  elseif not str then
    str = '\xff\xfd'
  end

  str = utf16be_to_utf8:match(str)
  if str == nil then
   str = "??"
   if ctx.warnings then
     ctx.warnings[#ctx.warnings + 1] = "UTF16 to UTF8 conversion failure"
   end
  end
  ctx.text_buffer[#ctx.text_buffer + 1] = str
end


local operators = {
  BT = function(scanner, ctx)
    assert(not ctx.text_mode)
    ctx.text_mode = true
  end,
  ET = function(scanner, ctx)
    assert(ctx.text_mode)
    ctx.text_mode = false
  end,
  Tf = function(scanner, ctx)
    assert(ctx.fonts)
    local size = scanner:popnumber()
    local name = scanner:popname()
    local font_type, font_ref, font_id = pdfe.getfromdictionary(ctx.fonts, name)
    assert(font_type == 10)
    local font_type, font = pdfe.getfromreference(font_ref)
    local enc = pdfe.getname(font,"Encoding")

    if enc and enc=="WinAnsiEncoding" then
      ctx.current_font = {
        enc="WinAnsiEncoding",
        id = font_id,
        obj = font,
        cmap = winansi_to_utf16be,
      }
    elseif font.ToUnicode then
      ctx.current_font = {
        id = font_id,
        obj = font,
      }
      if font.ToUnicode then
        local cmap, warnings = parse_cmap(font.ToUnicode)
        ctx.current_font.cmap = cmap
        if ctx.warnings then
          table.move(warnings, 1, #warnings, #ctx.warnings + 1, ctx.warnings)
        end
      end
    else
      ctx.current_font = {
        id = font_id,
        obj = font,
        cmap = nil,
      }
    end
  end,
  Tj = function(scanner, ctx)
    if not ctx.text_buffer then return end
    local font = ctx.current_font
    assert(ctx.text_mode and font)
    local text = scanner:popstring()
    print_string(ctx, text, font)
  end,
  TJ = function(scanner, ctx)
    if not ctx.text_buffer then return end
    local font = ctx.current_font
    assert(ctx.text_mode and font)
    local texts = scanner:poparray()
    for _, entry in ipairs(texts) do
      if entry[1] == 'string' then
        print_string(ctx, entry[2], font)
      end
    end
  end,
  BMC = function(scanner, ctx)
    local tag = scanner:popname()
    local stack = ctx.marked_stack
    local top = {
      tag = tag,
    }
    stack[#stack + 1] = top
    if tag == 'Artifact' then
      top.artifact = ctx.artifact
      ctx.artifact = true
    end
  end,
  BDC = function(scanner, ctx)
    local props = scanner:popdictionary() or ctx.properties and ctx.properties[scanner:popname()]
    if not props then
      props = {}
      if ctx.warnings then
        ctx.warnings[#ctx.warnings + 1] = "Missing properties in BDC"
      end
    end
    local tag = scanner:popname()
    local stack = ctx.marked_stack
    local top = {
      tag = tag,
      props = props,
    }
    stack[#stack + 1] = top
    if props.ActualText or props.MCID then
      top.text_buffer = ctx.text_buffer
      ctx.text_buffer = not props.ActualText and {}
      top.warnings = ctx.warnings
      ctx.warnings = not props.ActualText and {}
    end
    if tag == 'Artifact' then
      top.artifact = ctx.artifact
      ctx.artifact = true
    end
  end,
  EMC = function(scanner, ctx)
    local stack = ctx.marked_stack
    local top = assert(stack[#stack])
    stack[#stack] = nil
    local tag = top.tag
    top.tag = nil
    local props = top.props
    if props then
      top.props = nil
      local text
      local outer_text_buffer = top.text_buffer
      local outer_warnings = top.warnings
      local warnings = ctx.warnings
      if props.ActualText and (props.MCID or outer_text_buffer) then
        text = type(props) == 'table' and props.ActualText[2] or props.ActualText
        text = text_string_to_utf8:match(text)
        warnings = {}
      end
      if props.MCID then
        local MCID = type(props) == 'table' and props.MCID[2] or props.MCID
        if warnings and warnings[1] then
          ctx.marked_content_element_warnings[MCID] = warnings
        end
        text = text or table.concat(ctx.text_buffer)
        ctx.marked_content_elements[MCID] = text
      end
      if text and outer_text_buffer then
        outer_text_buffer[#outer_text_buffer + 1] = text
        table.move(warnings, 1, #warnings, #outer_warnings + 1, outer_warnings)
      end
    end
    for k, v in next, top do
      ctx[k] = v
    end
  end,
}
operators['"'] = operators.Tj
operators["'"] = operators.Tj

return function(stream, resources)
  local fonts = resources and resources.Font
  local ctx = {
    fonts = resources and resources.Font,
    properties = resources and resources.Properties,
    text_mode = false,
    marked_stack = {},
    artifact = false,
    text_buffer = false,
    warnings = false,
    -- current_font = nil,
    marked_content_elements = {},
    marked_content_element_warnings = {},
  }
  if pdfe.type(stream) == 'pdfe.array' then
    local arr = {}
    for i=1, #stream do
      arr[i] = stream[i]
    end
    stream = arr
  end
  local s,e
  s,e= pcall(function () return pdfscanner.scan(stream, operators, ctx) end)
  if s  then
 --  io.stderr:write("ok")
  else
    io.stderr:write("\n\n" ..tostring(e))
    io.stderr:write("\nError parsing marked content stream, returning empty marked content\n\n")
  end
  return ctx.marked_content_elements, ctx.marked_content_element_warnings
end
