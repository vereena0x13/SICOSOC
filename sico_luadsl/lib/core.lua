z        = word(0)
t0       = word()


function jump(addr)
    sble(t0, t0, addr)
end

function clear(addr)
    sble(addr, addr)
end

function set(a, b)
    clear(t0)
    sble(t0, b)
    clear(a)
    sble(a, t0)
end

function jeq(a, b, addr)
    --tmp1  tmp1  ?+1
    --tmp1  b     ?+1
    --tmp2  tmp2  ?+1
    --tmp2  tmp1  ?+1
    --tmp2  a     ?+1
    --tmp1  tmp1  ?+1
    --tmp2  tmp1  jmp
end