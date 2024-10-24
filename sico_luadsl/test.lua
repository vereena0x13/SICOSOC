local start = label()
sble(0, 0, start)


include "lib/core.lua"


local text = mark() ascii("Hello, World!\n")
local len  = mark() word(len.addr - text.addr)
local neg  = mark() word(-1)
local one  = mark() word(1)


local tstart = word(text.addr)
local left   = word(14)


mark(start)

local loop = label()
local hang = label()

mark(loop)  sble(65535, text)
            sble(left, one, hang)
            sble(at(pos() - 5), neg, loop)

mark(hang)  set(at(loop.addr + 1), tstart)
            set(left, len)
            jump(loop)