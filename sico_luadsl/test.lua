local loop = label()
local text = label()
local len  = label()
local neg  = label()
local one =  label()
local hang = label()

mark(loop)  sble(65535, text)
            sble(len, one, hang)
            sble(at(pos() - 5), neg, loop)

mark(hang)  sble(0, 0, hang)

mark(text)  ascii("Hello, World!\n")
mark(len)   word(len.addr - text.addr)
mark(neg)   word(-1)
mark(one)   word(1)