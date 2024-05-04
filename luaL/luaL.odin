package luau_vm_l
import "core:c"
import "../lua"
import "core:strings"

when ODIN_OS == .Windows {
    foreign import LuauVM {
        "../lib/Luau.VM.lib",
    }
} else {
    #panic("Unsupported OS. Report this.")
}

State :: lua.State
CFunction :: lua.CFunction
// VEC_LEN :: lua.VEC_LEN
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

    @(link_prefix = "where")
    _where :: proc(L: ^State, lvl: c.int) ---

    // errorL :: proc(L: ^State)

    checkoption :: proc(L: ^State, narg: c.int, def: cstring, lst: [^]cstring) -> c.int ---

    tolstring   :: proc(L: ^State, idx: c.int, len: ^c.size_t) -> cstring ---

    newstate :: proc() -> ^State ---

    findtable :: proc(L: ^State, idx: c.int, fname: cstring, szhint: c.int) -> cstring ---

    typename  :: proc(L: ^State, idx: c.int) -> cstring ---
}

checkstring :: proc(L: ^State, numArg: c.int) -> string {
    l: c.size_t
    cs := checklstring(L, numArg, &l)
    return strings.string_from_ptr(transmute([^]u8)cs, int(l))
}

optstring :: proc(L: ^State, numArg: c.int, def: cstring) -> string {
    l: c.size_t
    cs := optlstring(L, numArg, def, &l)
    return strings.string_from_ptr(transmute([^]u8)cs, int(l))
}

argcheck :: proc(L: ^State, cond: bool, arg: c.int, extramsg: cstring) {
    if !cond {
        argerrorL(L, arg, extramsg)
    }
}

argexpected :: proc(L: ^State, cond: bool, arg: c.int, tname: cstring) {
    if !cond {
        typeerrorL(L, arg, tname)
    }
}

getmetatable :: proc(L: ^State, n: cstring) -> c.int {
    return lua.getfield(L, lua.REGISTRYINDEX, n)
}

opt :: proc(L: ^State, f: #type proc(^State, c.int) -> c.int, n: c.int, d: c.int) -> bool {
    return lua.isnoneornil(L, bool(n) ? d : f(L, n))
}

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
