#!/bin/env luajit

local middleclass 	= require "middleclass"
local argparse 		= require "argparse"
local pprint		= require "pprint"
local path 			= require "pl.path"


local string_char 	= string.char
local string_byte 	= string.byte
local string_sub  	= string.sub
local string_format = string.format


local DATA_WIDTH 	= 16
local DATA_MAX_VAL  = math.pow(2, DATA_WIDTH)


function runSICO(code)
	local function Bus()
		local self = {}

		local memory = {}
		local devices = {}

		for i = 1, DATA_MAX_VAL do
			memory[i] = 0
		end

		self.add_device = function(device)
			local addr = device.addr
			local last = addr + device.size
			for i = addr, last - 1 do
				devices[i + 1] = device
			end
		end

		self.read = function(addr)
			if devices[addr + 1] ~= nil then
				return bit.band(devices[addr + 1].read(addr), 0xFFFF)
			else
				return memory[addr + 1]
			end
		end

		self.write = function(addr, value)
			if devices[addr + 1] ~= nil then
				return devices[addr + 1].write(addr, value)
			else
				memory[addr + 1] = value
				return true
			end
		end

		return self
	end


	local function interp(bus, start)
		local ip = start
		if not ip then ip = 0 end

		local function word()
			local x = bus.read(ip)
			ip = ip + 1
			return x
		end

		local maxIters = 100000
		while ip >= 0 and ip <= 65535 and maxIters > 0 do
			maxIters = maxIters - 1
			local a = word()
			local b = word()
			local c = word()
			local av = bus.read(a)
			local bv = bus.read(b)
			bus.write(a, bit.band(av - bv, 0xFFFF))
			if av <= bv then ip = c end
		end
	end

	
	local bus = Bus()

	bus.add_device({
		addr = 65535,
		size = 1,
		read = function(addr) return 0 end,
		write = function(addr, value)
			local v = (-value) % 65536
			print("write to 65535: " .. value .. " " .. v)
			if v <= 0 or v >= 255 then return false end
			io.write(string_char(v))
			io.flush()
			return true
		end
	})

	for i = 1, #code do
		bus.write(i - 1, code[i])
	end

	interp(bus, 0)
end


local function Assembler()
	local self = {}

	local code = {}
	local patches = {}

	local function emit(x)
		assert(type(x) == "number")
		code[#code + 1] = x
	end

	local function mark_patch(l)
		patches[#patches + 1] = { addr = #code, label = l }
	end

	self.pos = function()
		return #code
	end

	self.label = function()
		local l = {}
		return l
	end

	self.mark = function(l)
		if l then
			l.addr = self.pos()
			return l
		else
			local l = {}
			l.addr = self.pos()
			return l
		end
	end

	self.at = function(a)
		if a then
			return { addr = a }
		else
			return { addr = self.pos() }
		end
	end

	self.word = function(x)
		local l = self.mark()
		emit(x or 0)
		return l
	end

	self.sble = function(a, b, c)
		local ta = type(a)
		local tb = type(b)
		local tc = type(c)

		if ta == "table" then
			emit(0)
			mark_patch(a)
		elseif ta == "number" then
			emit(a)
		else
			error("unexpected '" .. tostring(a) .. "'")
		end

		if tb == "table" then
			emit(0)
			mark_patch(b)
		elseif tb == "number" then
			emit(b)
		else
			error("unexpected '" .. tostring(b) .. "'")
		end

		if tc == "table" then
			emit(0)
			mark_patch(c)
		elseif tc == "number" then
			emit(c)
		elseif c == nil then
			emit(self.pos() + 1)
		else
			error("unexpected '" .. tostring(c) .. "'")
		end
	end

	self.ascii = function(s)
		local l = self.mark()
		for i = 1, #s do
			emit(string_byte(string_sub(s, i, i)))
		end
		return l
	end

	self.asciiz = function(s)
		local l = self.ascii(s)
		emit(0)
		return l
	end

	self.assemble = function()
		for i = 1, #patches do
			local p = patches[i]
			local a = p.addr
			local l = p.label
			assert(l.addr)
			code[a] = l.addr	
		end

		for i = 1, #code do
			code[i] = bit.band(code[i], 0xFFFF)
		end

		return code
	end

	return self	
end


local opts = argparse()
opts:argument "file"
	:description "infile"
opts:option "-o" "--output"
	:description "outfile"
	:default "out.bin"
opts:flag "-p"
opts:flag "-r"

local args = opts:parse()


local func, err = loadfile(args.file)

if not func then
	print(err)
	return
end

local asm = Assembler()

local fenv = {
	label = asm.label,
	pos = asm.pos,
	mark = asm.mark,
	at = asm.at,
	word = asm.word,
	sble = asm.sble,
	ascii = asm.ascii,
	asciiz = asm.asciiz,
	string = _G.string,
	math = _G.math,
	table = _G.table,
	coroutine = _G.coroutine,
	xpcall = _G.xpcall,
	tostring = _G.tostring,
	print = _G.print,
	unpack = _G.unpack,
	next = _G.next,
	assert = _G.assert,
	tonumber = _G.tonumber,
	pcall = _G.pcall,
	type = _G.type,
	select = _G.select,
	pairs = _G.pairs,
	ipairs = _G.ipairs,
	error = _G.error,
    require = _G.require
}
fenv._G = fenv

local included = {}
fenv.include = function(file)
	if included[file] then
		return
	end
	included[file] = true

	local func, err = loadfile(file)

	if not func then
		error(err)
	end

	setfenv(func, fenv)
	local status, ret, err = xpcall(func, debug.traceback)
	if not status or err then
		error(ret)
	end
end

setfenv(func, fenv)

local status, ret, err = xpcall(func, debug.traceback)
if status and not err then
	local code = asm.assemble()

	print(string_format("assembled into %d words", #code))
	print()

	if args.p then
		for i = 1, #code do
			io.write(code[i])
			if i < #code then io.write(', ') end
		end
		io.write('\n')
	end

	local fh = io.open(args.output, "wb")
	for i = 1, #code do
		local v = code[i]
		local lo = bit.band(v, 0xFF)
		local hi = bit.band(bit.rshift(v, 8), 0xFF)
		fh:write(string.char(hi))
		fh:write(string.char(lo))
	end
	fh:close()


	if args.r then
		runSICO(code)
	end
else
	io.write("ERROR: ")
	print(ret)
end