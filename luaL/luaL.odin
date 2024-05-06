package luau_vm_L
import "core:c"
import "../lua"

when ODIN_OS == .Windows {
    foreign import LuauVM {
        "../lib/windows/Luau.VM.lib",
    }
} else {
    #panic("Unsupported OS(currently). If you want, make a PR with the compiled binaries for your OS.")
}

State :: lua.State
CFunction :: lua.CFunction
VEC_LEN :: 3

Reg :: struct {
    name: cstring,
    func: CFunction,
}

@(link_prefix = "luaL_")
foreign LuauVM {
    register     :: proc(L: ^State, libname: cstring, l: [^]Reg) ---
    getmetafield :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
    callmeta     :: proc(L: ^State, obj: c.int, e: cstring) -> c.int ---
    typeerrorL   :: proc(L: ^State, narg: c.int, tname: cstring) -> ! ---
    argerrorL    :: proc(L: ^State, narg: c.int, extramsg: cstring) -> ! ---
    checklstring :: proc(L: ^State, numArg: c.int, l: ^c.size_t) -> cstring ---
    optlstring   :: proc(L: ^State, numArg: c.int, def: cstring, l: ^c.size_t) -> cstring ---
    checknumber  :: proc(L: ^State, numArg: c.int) -> c.double ---
    optnumber    :: proc(L: ^State, nArg: c.int, def: c.double) -> c.double ---

    checkboolean :: proc(L: ^State, narg: c.int) -> c.int ---
    optboolean   :: proc(L: ^State, narg, def: c.int) -> c.int ---

    checkinteger  :: proc(L: ^State, numArg: c.int) -> c.int ---
    optinteger    :: proc(L: ^State, nArg, def: c.int) -> c.int ---
    checkunsigned :: proc(L: ^State, numArg: c.int) -> c.uint ---
    optunsigned   :: proc(L: ^State, numArg: c.int, def: c.uint) -> c.uint ---

    checkvector :: proc(L: ^State, narg: c.int) -> [VEC_LEN]c.float ---
    optvector   :: proc(L: ^State, narg: c.int, def: [VEC_LEN]c.float) -> [VEC_LEN]c.float ---

    checkstack :: proc(L: ^State, sz: c.int, msg: cstring) ---
    checktype  :: proc(L: ^State, narg, t: c.int) ---
    checkany   :: proc(L: ^State, narg: c.int) ---

    newmetatable :: proc(L: ^State, tname: cstring) -> c.int ---
    checkudata   :: proc(L: ^State, ud: c.int, tname: cstring) -> rawptr ---

    checkbuffer :: proc(L: ^State, narg: c.int, len: ^c.size_t) -> rawptr ---

    @(link_name = "where")
    _where :: proc(L: ^State, lvl: c.int) ---

    // errorL :: proc(L: ^State)

    checkoption :: proc(L: ^State, narg: c.int, def: cstring, lst: [^]cstring) -> c.int ---

    tolstring   :: proc(L: ^State, idx: c.int, len: ^c.size_t) -> cstring ---

    newstate :: proc() -> ^State ---

    findtable :: proc(L: ^State, idx: c.int, fname: cstring, szhint: c.int) -> cstring ---

    typename  :: proc(L: ^State, idx: c.int) -> cstring ---
}

checkstring :: proc "c" (L: ^State, numArg: c.int) -> string { return string(checklstring(L, numArg, nil)) }

optstring :: proc "c" (L: ^State, numArg: c.int, def: cstring) -> string { return string(optlstring(L, numArg, def, nil)) }

argcheck :: proc "c" (L: ^State, cond: bool, arg: c.int, extramsg: cstring) {
    if !cond {
        argerrorL(L, arg, extramsg)
    }
}

argexpected :: proc "c" (L: ^State, cond: bool, arg: c.int, tname: cstring) {
    if !cond {
        typeerrorL(L, arg, tname)
    }
}

getmetatable :: proc "c" (L: ^State, n: cstring) -> c.int { return lua.getfield(L, lua.REGISTRYINDEX, n) }

opt :: proc "c" (L: ^State, f: #type proc "c" (^State, c.int) -> c.int, n: c.int, d: c.int) -> bool { return lua.isnoneornil(L, bool(n) ? d : f(L, n)) }

// checkstring :: proc(L: ^State, n: c.int) {
//     return string(checklstring(L, n, nil))
// }

@(link_prefix = "luaL_")
foreign LuauVM {
    // builtin libraries
    @(link_prefix = "lua")
    open_base      :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_coroutine :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_table     :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_os        :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_string    :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_bit32     :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_buffer    :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_utf8      :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_math      :: proc(L: ^State) -> c.int ---

    @(link_prefix = "lua")
    open_debug     :: proc(L: ^State) -> c.int ---

    // open all builtin libraries
    openlibs     :: proc(L: ^State) ---

    // sandbox libraries and globals
    sandbox       :: proc(L: ^State) ---
    sandboxthread :: proc(L: ^State) ---
}

/******************************************************************************
 * Copyright (c) 2019-2023 Roblox Corporation
 * Copyright (C) 1994-2008 Lua.org, PUC-Rio.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 ******************************************************************************/

