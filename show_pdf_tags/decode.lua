local lpeg = lpeg or require'lpeg'

local utf16be_to_utf8 = lpeg.Cs((
  lpeg.R('\x00\xD7', '\xE0\xFF') * 1 / function(s)
    local high, low = string.byte(s, 1, 2)
    return utf8.char(high << 8 | low)
  end
  + lpeg.R'\xD8\xDB' * 1 * lpeg.R'\xDC\xDF' * 1 / function(s)
    local hh, hl, lh, ll = string.byte(s, 1, 4)
    return utf8.char(((hh & 3) << 12 | hl << 10 | (lh & 3) << 8 | ll) + 0x10000)
  end
  + lpeg.Cg(2 * lpeg.Cc('\u{FFFD}'))
)^0) * -1

local pdfdoc_mapping = {
  ['\x18'] = '\u{02D8}',
  ['\x19'] = '\u{02C7}',
  ['\x1A'] = '\u{02C6}',
  ['\x1B'] = '\u{02D9}',
  ['\x1C'] = '\u{02DD}',
  ['\x1D'] = '\u{02DB}',
  ['\x1E'] = '\u{02DA}',
  ['\x1F'] = '\u{02DC}',

  ['\x7F'] = '\u{FFFD}',
  ['\x80'] = '\u{2022}',
  ['\x81'] = '\u{2020}',
  ['\x82'] = '\u{2021}',
  ['\x83'] = '\u{2026}',
  ['\x84'] = '\u{2014}',
  ['\x85'] = '\u{2013}',
  ['\x86'] = '\u{0192}',
  ['\x87'] = '\u{2044}',
  ['\x88'] = '\u{2039}',
  ['\x89'] = '\u{203A}',
  ['\x8A'] = '\u{2212}',
  ['\x8B'] = '\u{2030}',
  ['\x8C'] = '\u{201E}',
  ['\x8D'] = '\u{201C}',
  ['\x8E'] = '\u{201D}',
  ['\x8F'] = '\u{2018}',
  ['\x90'] = '\u{2019}',
  ['\x91'] = '\u{201A}',
  ['\x92'] = '\u{2122}',
  ['\x93'] = '\u{FB01}',
  ['\x94'] = '\u{FB02}',
  ['\x95'] = '\u{0141}',
  ['\x96'] = '\u{0152}',
  ['\x97'] = '\u{0160}',
  ['\x98'] = '\u{0178}',
  ['\x99'] = '\u{017D}',
  ['\x9A'] = '\u{0131}',
  ['\x9B'] = '\u{0142}',
  ['\x9C'] = '\u{0153}',
  ['\x9D'] = '\u{0161}',
  ['\x9E'] = '\u{017E}',
  ['\x9F'] = '\u{FFFD}',
  ['\xA0'] = '\u{20AC}',
  ['\xAD'] = '\u{FFFD}',
}
local pdfdoc_to_utf8 = lpeg.Cs((
    lpeg.R('\x00\x17', '\x0D\x0D', '\x20\x7E')
  + lpeg.R('\xA1\xAC', '\xAE\xFF') / function(c) return utf8.char(string.byte(c)) end
  + lpeg.R('\x18\x1F', '\x7F\xA0', '\xAD\xAD') / pdfdoc_mapping
)^0) * -1

local text_string_to_utf8 = '\xFE\xFF' * utf16be_to_utf8 + '\u{FEFF}' * lpeg.C(lpeg.P(1)^0) * -1 + pdfdoc_to_utf8
return {
  utf16be_to_utf8 = utf16be_to_utf8,
  text_string_to_utf8 = text_string_to_utf8
}
