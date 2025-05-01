local startdict = {'special', 'startdict'}
local stopdict = {'special', 'stopdict'}
local startarray = {'special', 'startarray'}
local stoparray = {'special', 'stoparray'}
local names = setmetatable({}, {__index = function(t, i)
  local token = {'name', i}
  t[i] = token
  return token
end})
local operators = setmetatable({}, {__index = function(t, i)
  local token = {'operator', i}
  t[i] = token
  return token
end})

local parse_token do
  local l = lpeg or require'lpeg'

  local char = string.char
  local tonumber = tonumber

  local comment_token = '%' * (1-l.S'\r\n')^0 * (l.S'\r\n' + -1)
  local space_token = l.S' \r\n\t'
  local special_character = l.S' \n\r\t/[(<{}>)]%'

  local startdict_token = '<<' * l.Cc(startdict)
  local stopdict_token = '>>' * l.Cc(stopdict)
  local startarray_token = '[' * l.Cc(startarray)
  local stoparray_token = ']' * l.Cc(stoparray)
  local name_token = '/' * ((1-special_character)^0 / names)
  local number_token = (l.S'+-'^-1 * (l.R'09'^1 * ('.' * l.R'09'^0)^-1 + '.' * l.R'09'^1)) / tonumber
  local operator_token = (1-special_character)^1 / operators
  local boolean_token = ('true' * l.Cc(true) + 'false' * l.Cc(false)) * #(special_character + -1)

  local string_token = '(' * l.Cs(
    lpeg.P{(
        (1-l.S'()\\')^1
      + '(' * lpeg.V(1) * ')'
      + l.Cg('\\' * ('\n' * l.P'\r'^-1 + '\r' * l.P'\n'^-1) * l.Cc'')
      + l.Cg('\\' * (l.R'07' * l.R'07'^-2 / function(s) return char(tonumber(s, 8)) end))
      + l.Cg('\\' * (l.S'nrtbf'/{n = '\n', r = '\r', t = '\t', b = '\b', f = '\f'}))
      + l.Cg('\\' * l.C(l.S'()\\'^-1))
    )^0}
  ) * ')'
  local hexstring_token = '<' * l.Cs(
      (l.R('09', 'af', 'AF') * l.R('09', 'af', 'AF') / function(s) return char(tonumber(s, 16)) end + l.Cg(space_token^1 * l.Cc''))^0
    * (l.R('09', 'af', 'AF') / function(s) return char(tonumber(s, 16) * 16) end)^-1
  ) * '>'

  parse_token = space_token^0 * (comment_token * space_token^0)^0 * (
      startdict_token
    + stopdict_token
    + startarray_token
    + stoparray_token
    + string_token
    + name_token
    + hexstring_token
    + name_token
    + number_token
    + boolean_token
    + operator_token
    + -1 * l.Cc(nil)
  ) * l.Cp()
end

local function pop_value(operands)
  local stack_height = #operands
  local top_value = operands[stack_height]
  operands[stack_height] = nil
  if not top_value then return nil end
  local t = type(top_value)
  if t == 'number' then
    return {math.type(top_value) == 'integer' and 'integer' or 'real', top_value + 0.}
  elseif t == 'boolean' then
    return {'boolean', top_value}
  elseif t == 'string' then
    return {'string', top_value}
  elseif t == 'table' then
    if top_value[1] == 'special' then
      local kind = top_value[2]
      if kind == 'stopdict' then
        local dict = {}
        while operands[#operands] ~= startdict do
          local value = assert(pop_value(operands))
          local key = assert(pop_value(operands))
          assert(key[1] == 'name')
          dict[key[2]] = value
        end
        operands[#operands] = nil
        return {'dict', dict}
      elseif kind == 'stoparray' then
        local array, l = {}, 0
        while operands[#operands] ~= startarray do
          local value = assert(pop_value(operands))
          l = l + 1
          array[l] = value
        end
        operands[#operands] = nil
        for i = 1, l//2 do
          local opposite = l+1-i
          array[i], array[opposite] = array[opposite], array[i]
        end
        return {'array', array}
      else
        error'Unmatched'
      end
    else
      return table.move(top_value, 1, 2, 1, {})
      --return top_value
    end
  else
    assert(false)
  end
end

local scanner_index = {
  done = function(scanner) scanner.__is_done = true end,
  pop = function(scanner) return pop_value(scanner.__operands) end,
  popboolean = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if type(top_value) == 'boolean' then
      operands[#operands] = nil
      return top_value
    end
  end,
  popnumber = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if type(top_value) == 'number' then
      operands[#operands] = nil
      return top_value
    end
  end,
  popstring = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if type(top_value) == 'string' then
      operands[#operands] = nil
      return top_value
    end
  end,
  popname = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if type(top_value) == 'table' and top_value [1] == 'name' then
      operands[#operands] = nil
      return top_value[2]
    end
  end,
  poparray = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if top_value == stoparray then
      return pop_value(operands)[2]
    end
  end,
  popdictionary = function(scanner)
    local operands = scanner.__operands
    local top_value = operands[#operands]
    if top_value == stopdict then
      return pop_value(operands)[2]
    end
  end,
}
local scanner_meta = {
  __index = scanner_index,
}

local function build_scanner(context)
  return setmetatable({
    __is_done = false,
    __operands = {},
  }, scanner_meta)
end

-- Returns true when parsing should continue with next stream, false to terminate parsing and nil for errors.
local function scan_string(input, scanner, operators, info)
  if pdfe.type(input) == 'pdfe.stream' then input = pdfe.readwholestream(input, true) end

  local operands = scanner.__operands

  local position = 1
  while true do
    local token, new_position = parse_token:match(input, position)
    if not new_position then
      return nil, string.format('failed to parse token at offset %i', position)
    end
    if nil == token then return true end
    position = new_position

    if type(token) == 'table' and token[1] == 'operator' then
      local handler = operators[token[2]]
      if handler then
        handler(scanner, info)
        if scanner.__is_done then return false end
      end
      for i=1, #operators do operators[i] = nil end
    else
      table.insert(operands, token)
    end
  end

  return true
end

local function scan(data, operators, info)
  local scanner = build_scanner(context)
  if type(data) == 'table' or pdfe.type(data) == 'pdfe.array' then
    for i=1, #data do
      local result, err = scan_string(data[i], scanner, operators, info)
      if result == nil then
        error(err)
      elseif not result then
        return
      end
    end
  else
    local result, err = scan_string(data, scanner, operators, info)
    if result == nil then
      error(err)
    end
  end
end

return {
  scan = scan,
}
