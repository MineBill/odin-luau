// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
// This code is based on Lua 5.x implementation licensed under MIT License; see lua_LICENSE.txt for details
package lua_vm_l

import "../lua"
import "core:c"

when ODIN_OS == .Windows {
	foreign import LuauVM "../lib/windows/Luau.VM.lib"
} else {
	#panic(
		"Unsupported OS(currently). If you want, make a PR with the compiled binaries for your OS.",
	)
}

Reg :: struct {
	name: cstring,
	func: lua.CFunction,
}

@(default_calling_convention = "c", link_prefix = "luaL_")
foreign LuauVM {
	register :: proc(L: ^lua.State, libname: cstring, l: ^Reg) --- // luaL_register
	getmetafield :: proc(L: ^lua.State, obj: i32, e: cstring) -> i32 --- // luaL_getmetafield
	callmeta :: proc(L: ^lua.State, obj: i32, e: cstring) -> i32 --- // luaL_callmeta
	typeerrorL :: proc(L: ^lua.State, narg: i32, tname: cstring) --- // luaL_typeerrorL
	argerrorL :: proc(L: ^lua.State, narg: i32, extramsg: cstring) --- // luaL_argerrorL
	checklstring :: proc(L: ^lua.State, numArg: i32, l: ^c.size_t) -> cstring --- // luaL_checklstring
	optlstring :: proc(L: ^lua.State, numArg: i32, def: cstring, l: ^c.size_t) -> cstring --- // luaL_optlstring
	checknumber :: proc(L: ^lua.State, numArg: i32) -> f64 --- // luaL_checknumber
	optnumber :: proc(L: ^lua.State, nArg: i32, def: f64) -> f64 --- // luaL_optnumber
	checkboolean :: proc(L: ^lua.State, narg: i32) -> i32 --- // luaL_checkboolean
	optboolean :: proc(L: ^lua.State, narg: i32, def: i32) -> i32 --- // luaL_optboolean
	checkinteger :: proc(L: ^lua.State, numArg: i32) -> i32 --- // luaL_checkinteger
	checkinteger64 :: proc(L: ^lua.State, numArg: i32) -> i64 --- // luaL_checkinteger64
	optinteger :: proc(L: ^lua.State, nArg: i32, def: i32) -> i32 --- // luaL_optinteger
	optinteger64 :: proc(L: ^lua.State, nArg: i32, def: i64) -> i64 --- // luaL_optinteger64
	checkunsigned :: proc(L: ^lua.State, numArg: i32) -> u32 --- // luaL_checkunsigned
	optunsigned :: proc(L: ^lua.State, numArg: i32, def: u32) -> u32 --- // luaL_optunsigned
	checkvector :: proc(L: ^lua.State, narg: i32) -> ^f32 --- // luaL_checkvector
	optvector :: proc(L: ^lua.State, narg: i32, def: ^f32) -> ^f32 --- // luaL_optvector
	checkstack :: proc(L: ^lua.State, sz: i32, msg: cstring) --- // luaL_checkstack
	checktype :: proc(L: ^lua.State, narg: i32, t: i32) --- // luaL_checktype
	checkany :: proc(L: ^lua.State, narg: i32) --- // luaL_checkany
	newmetatable :: proc(L: ^lua.State, tname: cstring) -> i32 --- // luaL_newmetatable
	checkudata :: proc(L: ^lua.State, ud: i32, tname: cstring) -> rawptr --- // luaL_checkudata
	checkudatatagged :: proc(L: ^lua.State, ud: i32, tag: i32) -> rawptr --- // luaL_checkudatatagged
	checkbuffer :: proc(L: ^lua.State, narg: i32, len: ^c.size_t) -> rawptr --- // luaL_checkbuffer
	@(link_name = "where")
	_where :: proc(L: ^lua.State, lvl: i32) --- // luaL_where
	errorL :: proc(L: ^lua.State, fmt: cstring, #c_vararg _: ..any) --- // luaL_errorL
	checkoption :: proc(L: ^lua.State, narg: i32, def: cstring, lst: [^]cstring) -> i32 --- // luaL_checkoption
	tolstring :: proc(L: ^lua.State, idx: i32, len: ^c.size_t) -> cstring --- // luaL_tolstring
	newstate :: proc() -> ^lua.State --- // luaL_newstate
	findtable :: proc(L: ^lua.State, idx: i32, fname: cstring, szhint: i32) -> cstring --- // luaL_findtable
	typename :: proc(L: ^lua.State, idx: i32) -> cstring --- // luaL_typename
	traceback :: proc(L: ^lua.State, L1: ^lua.State, msg: cstring, level: i32) --- // luaL_traceback
}

// generic buffer manipulation
Strbuf :: struct {
	p:       cstring, // current position in buffer
	end:     cstring, // end of the current buffer
	L:       ^lua.State,
	storage: ^TString,
	buffer:  [512]i8,
}

TString :: struct {}

// compatibility typedef: this type is called luaL_Buffer in Lua headers
// renamed to luaL_Strbuf to reduce confusion with internal VM buffer type
Buffer :: Strbuf

@(default_calling_convention = "c", link_prefix = "luaL_")
foreign LuauVM {
	buffinit :: proc(L: ^lua.State, B: ^Strbuf) ---
	buffinitsize :: proc(L: ^lua.State, B: ^Strbuf, size: c.size_t) -> cstring ---
	prepbuffsize :: proc(B: ^Buffer, size: c.size_t) -> cstring ---
	addlstring :: proc(B: ^Strbuf, s: cstring, l: c.size_t) ---
	addvalue :: proc(B: ^Strbuf) ---
	addvalueany :: proc(B: ^Strbuf, idx: i32) ---
	pushresult :: proc(B: ^Strbuf) ---
	pushresultsize :: proc(B: ^Strbuf, size: c.size_t) ---

	// builtin libraries
	@(link_prefix = "lua")
	open_base :: proc(L: ^lua.State) -> i32 ---
}

COLIBNAME :: "coroutine"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_coroutine :: proc(L: ^lua.State) -> i32 ---
}

LUA_TABLIBNAME :: "table"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_table :: proc(L: ^lua.State) -> i32 ---
}

LUA_OSLIBNAME :: "os"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_os :: proc(L: ^lua.State) -> i32 ---
}

LUA_STRLIBNAME :: "string"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_string :: proc(L: ^lua.State) -> i32 ---
}

LUA_BITLIBNAME :: "bit32"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_bit32 :: proc(L: ^lua.State) -> i32 ---
}

LUA_BUFFERLIBNAME :: "buffer"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_buffer :: proc(L: ^lua.State) -> i32 ---
}

LUA_UTF8LIBNAME :: "utf8"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_utf8 :: proc(L: ^lua.State) -> i32 ---
}

LUA_CLASSLIBNAME :: "class"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_class :: proc(L: ^lua.State) -> i32 ---
}

LUA_MATHLIBNAME :: "math"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_math :: proc(L: ^lua.State) -> i32 ---
}

LUA_DBLIBNAME :: "debug"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_debug :: proc(L: ^lua.State) -> i32 ---
}

LUA_VECLIBNAME :: "vector"

@(default_calling_convention = "c", link_prefix = "lua")
foreign LuauVM {
	open_vector :: proc(L: ^lua.State) -> i32 ---
}

LUA_INTLIBNAME :: "integer"

@(default_calling_convention = "c", link_prefix = "luaL_")
foreign LuauVM {
	@(link_prefix = "lua")
	open_integer :: proc(L: ^lua.State) -> i32 ---

	// open all builtin libraries
	openlibs :: proc(L: ^lua.State) ---

	// sandbox libraries and globals
	sandbox :: proc(L: ^lua.State) ---
	sandboxthread :: proc(L: ^lua.State) ---
}
