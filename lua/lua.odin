package luau_vm
import "core:c"

when ODIN_OS == .Windows {
    foreign import LuauVM {
        "../lib/Luau.VM.lib",
    }
} else {
    #panic("Unsupported OS. Report this.")
}

REGISTRYINDEX :: (-MAXCSTACK - 2000)
ENVIRONINDEX  :: (-MAXCSTACK - 2001)
GLOBALSINDEX  :: (-MAXCSTACK - 2002)
upvalueindex :: #force_inline proc "c" (i: int) -> int {
    return GLOBALSINDEX - i
}
ispseudo :: #force_inline proc "c" (i: int) -> bool {
    return i <= REGISTRYINDEX
}

Status :: enum {
    OK = 0,
    YIELD,
    ERRRUN,
    ERRSYNTAX, // legacy error code, preserved for compatibility
    ERRMEM,
    ERRERR,
    BREAK, // yielded for a debug breakpoint
}

CoStatus :: enum {
    LUA_CORUN = 0, // running
    LUA_COSUS,     // suspended
    LUA_CONOR,     // 'normal' (it resumed another coroutine)
    LUA_COFIN,     // finished
    LUA_COERR,     // finished with error
}

State :: struct {}

CFunction    :: #type proc "c" (L: ^State) -> c.int
Continuation :: #type proc "c" (L: ^State, status: c.int) -> c.int

Alloc :: #type proc "c" (ud, ptr: rawptr, osize, nsize: c.size_t) -> rawptr

TNONE :: (-1)

Type :: enum c.int {
    NIL = 0,     // must be 0 due to lua_isnoneornil
    BOOLEAN = 1, // must be 1 due to l_isfalse


    LIGHTUSERDATA,
    NUMBER,
    VECTOR,

    STRING, // all types above this must be value types, all types below this must be GC types - see iscollectable


    TABLE,
    FUNCTION,
    USERDATA,
    THREAD,
    BUFFER,

    // values below this line are used in GCObject tags but may never show up in TValue type tags
    PROTO,
    UPVAL,
    DEADKEY,

    // the count of TValue type tags
    COUNT = PROTO
}

Number      :: c.double
Integer     :: c.int
Unsigned    :: c.uint

@(link_prefix="lua_")
foreign LuauVM {
    /*
    ** state manipulation
    */
    newstate :: proc(f: Alloc, ud: rawptr) -> ^State ---
    close :: proc(L: ^State) ---
    newthread :: proc(L: ^State) -> ^State ---
    mainthread :: proc(L: ^State) -> ^State ---
    resetthread :: proc(L: ^State) ---
    isthreadreset :: proc(L: ^State) -> c.int ---

    /*
    ** basic stack manipulation
    */
    absindex      :: proc(L: ^State, idx: c.int) -> c.int ---
    gettop        :: proc(L: ^State) -> c.int ---
    settop        :: proc(L: ^State, idx: c.int) ---
    pushvalue     :: proc(L: ^State, idx: c.int) ---
    remove        :: proc(L: ^State, idx: c.int) ---
    insert        :: proc(L: ^State, idx: c.int) ---
    replace       :: proc(L: ^State, idx: c.int) ---
    checkstack    :: proc(L: ^State, sz : c.int) -> c.int ---
    rawcheckstack :: proc(L: ^State, sz : c.int) --- // allows for unlimited stack frames

    xmove :: proc(from: ^State, to: ^State, n: c.int) ---
    xpush :: proc(from: ^State, to: ^State, idx: c.int) ---

    /*
    ** access functions (stack -> C)
    */

    isnumber :: proc(L: ^State, idx: c.int) -> c.int ---
    isstring    :: proc(L: ^State, idx: c.int) -> c.int   ---
    iscfunction :: proc(L: ^State, idx: c.int) -> c.int   ---
    isLfunction :: proc(L: ^State, idx: c.int) -> c.int   ---
    isuserdata  :: proc(L: ^State, idx: c.int) -> c.int   ---
    type        :: proc(L: ^State, idx: c.int) -> Type   ---
    typename    :: proc(L: ^State, tp:  c.int) -> cstring ---

    equal    :: proc(L: ^State, idx1, idx2: c.int) -> c.int ---
    rawequal :: proc(L: ^State, idx1, idx2: c.int) -> c.int ---
    lessthan :: proc(L: ^State, idx1, idx2: c.int) -> c.int ---

    tonumberx               :: proc(L: ^State, idx : c.int, isnum: ^c.int)    -> c.double   ---
    tointegerx              :: proc(L: ^State, idx : c.int, isnum: ^c.int)    -> c.int      ---
    tounsignedx             :: proc(L: ^State, idx : c.int, isnum: ^c.int)    -> c.uint     ---
    tovector                :: proc(L: ^State, idx : c.int)                   -> [^]c.float ---
    toboolean               :: proc(L: ^State, idx : c.int)                   -> c.int      ---
    tolstring               :: proc(L: ^State, idx : c.int, len  : ^c.size_t) -> cstring    ---
    tostringatom            :: proc(L: ^State, idx : c.int, atom : ^c.int)    -> cstring    ---
    namecallatom            :: proc(L: ^State, atom: [^]c.int)                -> cstring    ---
    objlen                  :: proc(L: ^State, idx : c.int)                   -> c.int      ---
    tocfunction             :: proc(L: ^State, idx : c.int)                   -> CFunction  ---
    tolightuserdata         :: proc(L: ^State, idx : c.int)                   -> rawptr     ---
    tolightuserdatatagged   :: proc(L: ^State, idx : c.int, tag  : c.int)     -> rawptr     ---
    touserdata              :: proc(L: ^State, idx : c.int)                   -> rawptr     ---
    touserdatatagged        :: proc(L: ^State, idx : c.int, tag  : c.int)     -> rawptr     ---
    userdatatag             :: proc(L: ^State, idx : c.int)                   -> c.int      ---
    lightuserdatatag        :: proc(L: ^State, idx : c.int)                   -> c.int      ---
    tothread                :: proc(L: ^State, idx : c.int)                   -> ^State     ---
    tobuffer                :: proc(L: ^State, idx : c.int, len  : ^c.size_t) -> rawptr     ---
    topointer               :: proc(L: ^State, idx : c.int)                   -> rawptr     ---

    /*
    ** push functions (C -> stack)
    */

    pushnil                      :: proc(L: ^State) ---
    pushnumber                   :: proc(L: ^State, n: c.double) ---
    pushinteger                  :: proc(L: ^State, n: c.int) ---
    pushunsigned                 :: proc(L: ^State, n: c.uint) ---
    // LUA_API void lua_pushvector   :: proc(L: ^State, float x, float y, float z, float w)
    pushvector                   :: proc(L: ^State, x, y, z: c.float) ---
    pushlstring                  :: proc(L: ^State, s: cstring, l: c.size_t) ---
    pushstring                   :: proc(L: ^State, s: cstring) ---

    // lua_pushvfstring                 :: proc(L: ^State, fmt: cstring, argp: c.va_list) -> cstring ---
    // lua_pushfstringL                 :: proc(lua_State* L, const char* fmt, ...) -> cstring ---

    pushcclosurek           :: proc(L: ^State, fn: CFunction, debugname: cstring, nup: c.int, cont: Continuation) ---
    pushboolean             :: proc(L: ^State, b: c.int) ---
    pushthread               :: proc(L: ^State) -> c.int ---

    pushlightuserdatatagged :: proc(L: ^State, p: rawptr, tag: c.int) ---
    newuserdatatagged       :: proc(L: ^State, sz: c.size_t, tag: c.int) -> rawptr ---
    newuserdatadtor         :: proc(L: ^State, sz: c.size_t, dtor: #type proc(rawptr) -> rawptr) -> rawptr ---

    newbuffer               :: proc(L: ^State, sz: c.size_t) -> rawptr ---

    /*
    ** get functions (Lua -> stack)
    */
    gettable    :: proc(L: ^State, idx: c.int) -> c.int ---
    getfield    :: proc(L: ^State, idx: c.int, k: cstring) -> c.int ---
    rawgetfield :: proc(L: ^State, idx: c.int, k: cstring) -> c.int ---
    rawget      :: proc(L: ^State, idx: c.int) -> c.int ---
    rawgeti     :: proc(L: ^State, idx, n: c.int) -> c.int ---
    createtable :: proc(L: ^State, narr, nrec: c.int) ---

    setreadonly :: proc(L: ^State, idx, enabled: c.int) ---
    getreadonly :: proc(L: ^State, idx: c.int) -> c.int ---
    setsafeenv  :: proc(L: ^State, idx, enabled: c.int) ---

    getmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
    getfenv      :: proc(L: ^State, idx: c.int) ---

    /*
    ** set functions (stack -> Lua)
    */
    settable    :: proc(L: ^State, idx: c.int) ---
    setfield    :: proc(L: ^State, idx: c.int, k: cstring) ---
    rawsetfield :: proc(L: ^State, idx: c.int, k: cstring) ---
    rawset      :: proc(L: ^State, idx: c.int) ---
    rawseti     :: proc(L: ^State, idx, n: c.int) ---
    setmetatable :: proc(L: ^State, objindex: c.int) -> c.int ---
    setfenv      :: proc(L: ^State, idx: c.int) -> c.int ---

    /*
    ** `load' and `call' functions (load and run Luau bytecode)
    */
    @(link_prefix = "luau_")
    load :: proc(L: ^State, chunkname: cstring, data: cstring, size: c.size_t, env: c.int) -> c.int ---
    call  :: proc(L: ^State, nargs, nresults: c.int) ---
    pcall :: proc(L: ^State, nargs, nresults, errfunc: c.int) -> c.int ---

    /*
    ** coroutine functions
    */
    lua_yield       :: proc(L: ^State, nresults: c.int) -> c.int ---
    lua_break       :: proc(L: ^State) -> c.int ---
    lua_resume      :: proc(L: ^State, from: ^State, narg: c.int) -> c.int ---
    lua_resumeerror :: proc(L: ^State, from: ^State) -> c.int ---
    lua_status      :: proc(L: ^State) -> c.int ---
    lua_isyieldable :: proc(L: ^State) -> c.int ---
    lua_getthreaddata :: proc(L: ^State) -> rawptr ---
    lua_setthreaddata :: proc(L: ^State, data: rawptr) ---
    lua_costatus      :: proc(L: ^State, co: ^State) -> c.int ---
}

GCOp :: enum {
    // stop and resume incremental garbage collection
    GCSTOP,
    GCRESTART,

    // run a full GC cycle not recommended for latency sensitive applications
    GCCOLLECT,

    // return the heap size in KB and the remainder in bytes
    GCCOUNT,
    GCCOUNTB,

    // return 1 if GC is active (not stopped) note that GC may not be actively collecting even if it's running
    GCISRUNNING,

    /*
    ** perform an explicit GC step, with the step size specified in KB
    **
    ** garbage collection is handled by 'assists' that perform some amount of GC work matching pace of allocation
    ** explicit GC steps allow to perform some amount of work at custom points to offset the need for GC assists
    ** note that GC might also be paused for some duration (until bytes allocated meet the threshold)
    ** if an explicit step is performed during this pause, it will trigger the start of the next collection cycle
    */
    GCSTEP,

    /*
    ** tune GC parameters G (goal), S (step multiplier) and step size (usually best left ignored)
    **
    ** garbage collection is incremental and tries to maintain the heap size to balance memory and performance overhead
    ** this overhead is determined by G (goal) which is the ratio between total heap size and the amount of live data in it
    ** G is specified in percentages by default G=200% which means that the heap is allowed to grow to ~2x the size of live data.
    **
    ** collector tries to collect S% of allocated bytes by interrupting the application after step size bytes were allocated.
    ** when S is too small, collector may not be able to catch up and the effective goal that can be reached will be larger.
    ** S is specified in percentages by default S=200% which means that collector will run at ~2x the pace of allocations.
    **
    ** it is recommended to set S in the interval [100 / (G - 100), 100 + 100 / (G - 100))] with a minimum value of 150% for example:
    ** - for G=200%, S should be in the interval [150%, 200%]
    ** - for G=150%, S should be in the interval [200%, 300%]
    ** - for G=125%, S should be in the interval [400%, 500%]
    */
    GCSETGOAL,
    GCSETSTEPMUL,
    GCSETSTEPSIZE,
}

Destructor :: #type proc "c" (L: ^State, userdata: rawptr)


@(link_prefix = "lua_")
foreign LuauVM {
    gc :: proc(L: ^State, what, data: c.int) -> c.int ---

    /*
    ** memory statistics
    ** all allocated bytes are attributed to the memory category of the running thread (0..LUA_MEMORY_CATEGORIES-1)
    */

    setmemcat  :: proc(L: ^State, category: c.int) ---
    totalbytes :: proc(L: ^State, category: c.int) -> c.size_t ---

    /*
    ** miscellaneous functions
    */

    error :: proc(L: ^State) -> ! ---

    next :: proc(L: ^State, idx: c.int) -> c.int ---
    rawiter :: proc(L: ^State, idx, iter: c.int) -> c.int ---

    concat :: proc(L: ^State, n: c.int) ---

    encodepointer :: proc(L: ^State, p: c.uintptr_t) -> c.uintptr_t ---

    clock :: proc() -> c.double ---

    setuserdatatag :: proc(L: ^State, idx, tag: c.int) ---

    setuserdatadtor :: proc(L: ^State, tag: c.int, dtor: Destructor) ---
    getuserdatadtor :: proc(L: ^State, tag: c.int) -> Destructor ---

    setlightuserdataname :: proc(L: ^State, tag: c.int, name: cstring) ---
    getlightuserdataname :: proc(L: ^State, tag: c.int) -> cstring ---

    clonefunction :: proc(L: ^State, idx: c.int) ---

    cleartable :: proc(L: ^State, idx: c.int) ---

    getallocf :: proc(L: ^State, ud: ^rawptr) -> Alloc ---

    ref   :: proc(L: ^State, idx: c.int) -> c.int ---
    unref :: proc(L: ^State, ref: c.int) ---
}

NOREF :: (-1)
REFNIL :: 0

    // rawgeti     :: proc(L: ^State, idx, n: c.int) -> c.int ---
getref :: proc "c" (L: ^State, ref: c.int) -> c.int {
    return rawgeti(L, 0, ref)
}

/*
** ===============================================================
** some useful macros
** ===============================================================
*/
tonumber   :: #force_inline proc "c" (L: ^State, #any_int i: c.int) -> c.double { return tonumberx(L, i, nil) }
tointeger  :: #force_inline proc "c" (L: ^State, #any_int i: c.int) -> c.int { return tointegerx(L, i, nil) }
tounsigned :: #force_inline proc "c" (L: ^State, #any_int i: c.int) -> c.uint { return tounsignedx(L, i, nil) }

pop :: #force_inline proc "c" (L: ^State, #any_int n: c.int) { settop(L, -n - 1) }

newtable    :: #force_inline proc "c" (L: ^State) { createtable(L, 0, 0) }
newuserdata :: #force_inline proc "c" (L: ^State, #any_int s: c.size_t) -> rawptr { return newuserdatatagged(L, s, 0) }

strlen :: #force_inline proc "c" (L: ^State, #any_int i: c.int) -> c.int { return objlen(L, i) }

isfunction      :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .FUNCTION }
istable         :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .TABLE }
islightuserdata :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .LIGHTUSERDATA }
isnil           :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .NIL }
isboolean       :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .BOOLEAN }
isvector        :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .VECTOR }
isthread        :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .THREAD }
isbuffer        :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) == .BUFFER }
isnone          :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return cast(c.int) type(L, n) == TNONE }
isnoneornil     :: #force_inline proc "c" (L: ^State, n: c.int) -> bool { return type(L, n) <= .NIL }
is              :: #force_inline proc "c" (L: ^State, n: c.int, t: Type) -> bool { return type(L, n) == t }

pushliteral   :: #force_inline proc "c" (L: ^State, s: string) { pushlstring(L, cast(cstring) raw_data(s), cast(c.size_t) len(s)) }
pushcfunction :: #force_inline proc "c" (L: ^State, fn: CFunction, debug_name: cstring) { pushcclosurek(L, fn, debug_name, 0, nil) }
pushcclosure  :: #force_inline proc "c" (L: ^State, fn: CFunction, debug_name: cstring, nup: c.int) { pushcclosurek(L, fn, debug_name, nup, nil) }
pushlightuserdata :: #force_inline proc "c" (L: ^State, p: rawptr) { pushlightuserdatatagged(L, p, 0) }

setglobal :: proc "c" (L: ^State, s: cstring) {
    setfield(L, GLOBALSINDEX, s)
}

getglobal :: proc "c" (L: ^State, s: cstring) -> c.int {
    return getfield(L, GLOBALSINDEX, s)
}

tostring :: proc "c" (L: ^State, i: c.int) -> string {
    return string(tolstring(L, i, nil))
}

// pushfstring :: proc() {}

Debug :: struct {
    name, what, source, short_src: cstring,
    linedefined, currentline: c.int,
    nupvals, nparams: c.uchar,
    isvararg: c.char,
    userdata: rawptr,
    ssbuf: [IDSIZE]c.char,
}

Hook     :: #type proc "c" (L: ^State, ar: ^Debug)
Coverage :: #type proc "c" (ctx, function: rawptr, linedefined, depth: c.int, hits: [^]c.int, size: c.size_t)

@(link_prefix = "lua_")
foreign LuauVM {
    stackdepth  :: proc(L: ^State) -> c.int ---
    getinfo     :: proc(L: ^State, level: c.int, what: cstring, ar: ^Debug) -> c.int ---
    getargument :: proc(L: ^State, level, n: c.int) -> c.int ---
    getlocal    :: proc(L: ^State, level, n: c.int) -> cstring ---
    setlocal    :: proc(L: ^State, level, n: c.int) -> cstring ---
    getupvalue  :: proc(L: ^State, funcindex, n: c.int) -> cstring ---
    setupvalue  :: proc(L: ^State, funcindex, n: c.int) -> cstring ---

    singlestep :: proc(L: ^State, enabled: b32) ---
    breakpoint :: proc(L: ^State, funcindex, line: c.int, enabled: b32) -> c.int ---

    getcoverage :: proc(L: ^State, funcindex: c.int, ctx: rawptr, callback: Coverage) ---

    // Warning: this function is not thread-safe since it stores the result in a shared global array! Only use for debugging.
    debugtrace :: proc(L: ^State) -> cstring ---

    callbacks :: proc(L: ^State) -> ^Callbacks ---
}

Callbacks :: struct {
    userdata: rawptr,

    interrupt: #type proc(L: ^State, gc: c.int),
    panic: #type proc(L: ^State, errcode: c.int),

    userthread: #type proc(LP: ^State, L: ^State),
    useratom: #type proc(s: cstring, l: c.size_t) -> c.int16_t,

    debugbreak: #type proc(L: ^State, ar: ^Debug),
    debugstep: #type proc(L: ^State, ar: ^Debug),
    debuginterrupt: #type proc(L: ^State, ar: ^Debug),
    debugprotectederror: #type proc(L: ^State),
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
