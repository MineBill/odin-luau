// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
// This code is based on Lua 5.x implementation licensed under MIT License; see lua_LICENSE.txt for details
package lua_vm

import "core:c"

when ODIN_OS == .Windows {
	foreign import LuauVM "../lib/windows/Luau.VM.lib"
} else {
	#panic("Unsupported OS(currently). If you want, make a PR with the compiled binaries for your OS.")
}

// option for multiple returns in `lua_pcall' and `lua_call'
MULTRET :: (-1)

/*
** pseudo-indices
*/
REGISTRYINDEX :: (-8000 - 2000)
ENVIRONINDEX :: (-8000 - 2001)
GLOBALSINDEX :: (-8000 - 2002)

// thread status; 0 is OK
Status :: enum i32 {
	OK        = 0,
	YIELD     = 1,
	ERRRUN    = 2,
	ERRSYNTAX = 3, // legacy error code, preserved for compatibility
	ERRMEM    = 4,
	ERRERR    = 5,
	BREAK     = 6, // yielded for a debug breakpoint
}

CoStatus :: enum i32 {
	RUN = 0, // running
	SUS = 1, // suspended
	NOR = 2, // 'normal' (it resumed another coroutine)
	FIN = 3, // finished
	ERR = 4, // finished with error
}

State :: struct {}
CFunction :: proc "c" (L: ^State) -> i32
Continuation :: proc "c" (L: ^State, status: i32) -> i32

/*
** prototype for memory-allocation functions
*/
Alloc :: proc "c" (ud: rawptr, ptr: rawptr, osize: c.size_t, nsize: c.size_t) -> rawptr

// `type` is an opaque VM-defined value which identifies the caged heap allocation kind
// separating allocations of different types is recommended
CageAlloc :: proc "c" (
	ud: rawptr,
	ptr: rawptr,
	osize: c.size_t,
	nsize: c.size_t,
	type: i32,
) -> rawptr

/*
** basic types
*/
TNONE :: (-1)

/*
* WARNING: if you change the order of this enumeration,
* grep "ORDER TYPE"
*/
// clang-format off
Type :: enum i32 {
	NIL           = 0, // must be 0 due to lua_isnoneornil
	BOOLEAN       = 1, // must be 1 due to l_isfalse
	LIGHTUSERDATA = 2,
	NUMBER        = 3,
	INTEGER       = 4,
	VECTOR        = 5,
	STRING        = 6, // all types above this must be value types, all types below this must be GC types - see iscollectable
	TABLE         = 7,
	FUNCTION      = 8,
	USERDATA      = 9,
	THREAD        = 10,
	BUFFER        = 11,
	CLASS         = 12,
	OBJECT        = 13,

	// values below this line are used in GCObject tags but may never show up in TValue type tags

	// LUA_TDEADKEY is used in TKey to identify Luau table entries that have the value set to nil,
	// so that we can remove the strong reference to the key.
	DEADKEY       = 14,

	// These values should never show up in TValue tag types.
	PROTO         = 15,
	UPVAL         = 16,

	// the count of all Luau types (including those that are never TValue type tags)
	_ALL          = 17,

	// the count of TValue type tags
	_COUNT        = 14,
}

// type of numbers in Luau
Number :: f64

// type for integer functions
Integer :: i32

// unsigned integer type
Unsigned :: u32

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	/*
	** state manipulation
	*/
	newstate :: proc(allocator: Alloc, ud: rawptr) -> ^State ---
	close :: proc(L: ^State) ---
	newthread :: proc(L: ^State) -> ^State ---
	mainthread :: proc(L: ^State) -> ^State ---
	resetthread :: proc(L: ^State) ---
	isthreadreset :: proc(L: ^State) -> i32 ---

	/*
	** basic stack manipulation
	*/
	absindex :: proc(L: ^State, idx: i32) -> i32 ---
	gettop :: proc(L: ^State) -> i32 ---
	settop :: proc(L: ^State, idx: i32) ---
	pushvalue :: proc(L: ^State, idx: i32) ---
	remove :: proc(L: ^State, idx: i32) ---
	insert :: proc(L: ^State, idx: i32) ---
	replace :: proc(L: ^State, idx: i32) ---
	checkstack :: proc(L: ^State, sz: i32) -> i32 ---
	rawcheckstack :: proc(L: ^State, sz: i32) --- // allows for unlimited stack frames
	xmove :: proc(from: ^State, to: ^State, n: i32) ---
	xpush :: proc(from: ^State, to: ^State, idx: i32) ---

	/*
	** access functions (stack -> C)
	*/
	isnumber :: proc(L: ^State, idx: i32) -> i32 ---
	isstring :: proc(L: ^State, idx: i32) -> i32 ---
	isinteger64 :: proc(L: ^State, idx: i32) -> i32 ---
	iscfunction :: proc(L: ^State, idx: i32) -> i32 ---
	isLfunction :: proc(L: ^State, idx: i32) -> i32 ---
	isuserdata :: proc(L: ^State, idx: i32) -> i32 ---
	type :: proc(L: ^State, idx: i32) -> i32 ---
	typename :: proc(L: ^State, tp: i32) -> cstring ---
	equal :: proc(L: ^State, idx1: i32, idx2: i32) -> i32 ---
	rawequal :: proc(L: ^State, idx1: i32, idx2: i32) -> i32 ---
	lessthan :: proc(L: ^State, idx1: i32, idx2: i32) -> i32 ---
	tonumberx :: proc(L: ^State, idx: i32, isnum: ^i32) -> f64 ---
	tointegerx :: proc(L: ^State, idx: i32, isnum: ^i32) -> i32 ---
	tounsignedx :: proc(L: ^State, idx: i32, isnum: ^i32) -> u32 ---
	tovector :: proc(L: ^State, idx: i32) -> ^f32 ---
	toboolean :: proc(L: ^State, idx: i32) -> i32 ---
	tointeger64 :: proc(L: ^State, idx: i32, isinteger: ^i32) -> i64 ---
	tolstring :: proc(L: ^State, idx: i32, len: ^c.size_t) -> cstring ---
	tostringatom :: proc(L: ^State, idx: i32, atom: ^i32) -> cstring ---
	tolstringatom :: proc(L: ^State, idx: i32, len: ^c.size_t, atom: ^i32) -> cstring ---
	namecallatom :: proc(L: ^State, atom: ^i32) -> cstring ---
	objlen :: proc(L: ^State, idx: i32) -> i32 ---
	tocfunction :: proc(L: ^State, idx: i32) -> CFunction ---
	tolightuserdata :: proc(L: ^State, idx: i32) -> rawptr ---
	tolightuserdatatagged :: proc(L: ^State, idx: i32, tag: i32) -> rawptr ---
	touserdata :: proc(L: ^State, idx: i32) -> rawptr ---
	touserdatatagged :: proc(L: ^State, idx: i32, tag: i32) -> rawptr ---
	userdatatag :: proc(L: ^State, idx: i32) -> i32 ---
	lightuserdatatag :: proc(L: ^State, idx: i32) -> i32 ---
	tothread :: proc(L: ^State, idx: i32) -> ^State ---
	tobuffer :: proc(L: ^State, idx: i32, len: ^c.size_t) -> rawptr ---
	topointer :: proc(L: ^State, idx: i32) -> rawptr ---

	/*
	** push functions (C -> stack)
	*/
	pushnil :: proc(L: ^State) ---
	pushnumber :: proc(L: ^State, n: f64) ---
	pushinteger :: proc(L: ^State, n: i32) ---
	pushinteger64 :: proc(L: ^State, n: i64) ---
	pushunsigned :: proc(L: ^State, n: u32) ---
	pushvector :: proc(L: ^State, x: f32, y: f32, z: f32) ---
	pushlstring :: proc(L: ^State, s: cstring, l: c.size_t) ---
	pushstring :: proc(L: ^State, s: cstring) ---
	pushvfstring :: proc(L: ^State, fmt: cstring, argp: c.va_list) -> cstring ---
	pushfstringL :: proc(L: ^State, fmt: cstring, #c_vararg _: ..any) -> cstring ---
	pushcclosurek :: proc(L: ^State, fn: CFunction, debugname: cstring, nup: i32, cont: Continuation) ---
	pushboolean :: proc(L: ^State, b: i32) ---
	pushthread :: proc(L: ^State) -> i32 ---
}

Destructor :: proc "c" (L: ^State, userdata: rawptr)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	pushlightuserdatatagged :: proc(L: ^State, p: rawptr, tag: i32) ---
	newuserdatatagged :: proc(L: ^State, sz: c.size_t, tag: i32) -> rawptr ---
	newuserdatataggedwithmetatable :: proc(L: ^State, sz: c.size_t, tag: i32) -> rawptr --- // metatable fetched with lua_getuserdatametatable
	newuserdatadtor :: proc(L: ^State, sz: c.size_t, dtor: Destructor) -> rawptr ---
	newbuffer :: proc(L: ^State, sz: c.size_t) -> rawptr ---

	/*
	** get functions (Lua -> stack)
	*/
	gettable :: proc(L: ^State, idx: i32) -> i32 ---
	getfield :: proc(L: ^State, idx: i32, k: cstring) -> i32 ---
	rawgetfield :: proc(L: ^State, idx: i32, k: cstring) -> i32 ---
	rawget :: proc(L: ^State, idx: i32) -> i32 ---
	rawgeti :: proc(L: ^State, idx: i32, n: i32) -> i32 ---
	rawgetptagged :: proc(L: ^State, idx: i32, p: rawptr, tag: i32) -> i32 ---
	createtable :: proc(L: ^State, narr: i32, nrec: i32) ---
	setreadonly :: proc(L: ^State, idx: i32, enabled: i32) ---
	getreadonly :: proc(L: ^State, idx: i32) -> i32 ---
	setsafeenv :: proc(L: ^State, idx: i32, enabled: i32) ---
	getmetatable :: proc(L: ^State, objindex: i32) -> i32 ---
	getfenv :: proc(L: ^State, idx: i32) ---

	/*
	** set functions (stack -> Lua)
	*/
	settable :: proc(L: ^State, idx: i32) ---
	setfield :: proc(L: ^State, idx: i32, k: cstring) ---
	rawsetfield :: proc(L: ^State, idx: i32, k: cstring) ---
	rawset :: proc(L: ^State, idx: i32) ---
	rawseti :: proc(L: ^State, idx: i32, n: i32) ---
	rawsetptagged :: proc(L: ^State, idx: i32, p: rawptr, tag: i32) ---
	setmetatable :: proc(L: ^State, objindex: i32) -> i32 ---
	setfenv :: proc(L: ^State, idx: i32) -> i32 ---

	/*
	** `load' and `call' functions (load and run Luau bytecode)
	*/
	@(link_prefix = "luau_")
	load :: proc(L: ^State, chunkname: cstring, data: cstring, size: c.size_t, env: i32) -> i32 ---
	call :: proc(L: ^State, nargs: i32, nresults: i32) ---
	pcall :: proc(L: ^State, nargs: i32, nresults: i32, errfunc: i32) -> i32 ---
	cpcall :: proc(L: ^State, func: CFunction, ud: rawptr) -> i32 ---

	// wrapper for making calls from yieldable C functions
	callyieldable :: proc(L: ^State, nargs: i32, nresults: i32) -> i32 ---
	pcallyieldable :: proc(L: ^State, nargs: i32, nresults: i32, errfunc: i32) -> i32 ---

	/*
	** coroutine functions
	*/
	yield :: proc(L: ^State, nresults: i32) -> i32 ---
	@(link_name = "break")
	_break :: proc(L: ^State) -> i32 ---
	resume :: proc(L: ^State, from: ^State, narg: i32) -> i32 ---
	resumeerror :: proc(L: ^State, from: ^State) -> i32 ---
	status :: proc(L: ^State) -> i32 ---
	isyieldable :: proc(L: ^State) -> i32 ---
	getthreaddata :: proc(L: ^State) -> rawptr ---
	setthreaddata :: proc(L: ^State, data: rawptr) ---
	costatus :: proc(L: ^State, co: ^State) -> i32 ---
	hasfinalizers :: proc(L: ^State) -> i32 ---
	pushfinalizerfunction :: proc(L: ^State, co: ^State, toclose: i32) ---
	addfinalizer :: proc(L: ^State, co: ^State, idx: i32) ---
}

/*
** garbage-collection function and options
*/
GCOp :: enum i32 {
	// stop and resume incremental garbage collection
	STOP        = 0,
	RESTART     = 1,

	// run a full GC cycle; not recommended for latency sensitive applications
	COLLECT     = 2,

	// return the heap size in KB and the remainder in bytes
	COUNT       = 3,
	COUNTB      = 4,

	// return 1 if GC is active (not stopped); note that GC may not be actively collecting even if it's running
	ISRUNNING   = 5,

	/*
	** perform an explicit GC step, with the step size specified in KB
	**
	** garbage collection is handled by 'assists' that perform some amount of GC work matching pace of allocation
	** explicit GC steps allow to perform some amount of work at custom points to offset the need for GC assists
	** note that GC might also be paused for some duration (until bytes allocated meet the threshold)
	** if an explicit step is performed during this pause, it will trigger the start of the next collection cycle
	*/
	STEP        = 6,

	/*
	** tune GC parameters G (goal), S (step multiplier) and step size (usually best left ignored)
	**
	** garbage collection is incremental and tries to maintain the heap size to balance memory and performance overhead
	** this overhead is determined by G (goal) which is the ratio between total heap size and the amount of live data in it
	** G is specified in percentages; by default G=200% which means that the heap is allowed to grow to ~2x the size of live data.
	**
	** collector tries to collect S% of allocated bytes by interrupting the application after step size bytes were allocated.
	** when S is too small, collector may not be able to catch up and the effective goal that can be reached will be larger.
	** S is specified in percentages; by default S=200% which means that collector will run at ~2x the pace of allocations.
	**
	** it is recommended to set S in the interval [100 / (G - 100), 100 + 100 / (G - 100))] with a minimum value of 150%; for example:
	** - for G=200%, S should be in the interval [150%, 200%]
	** - for G=150%, S should be in the interval [200%, 300%]
	** - for G=125%, S should be in the interval [400%, 500%]
	*/
	SETGOAL     = 7,
	SETSTEPMUL  = 8,
	SETSTEPSIZE = 9,

	// return 1 if GC is in a paused state; making a GC step in a paused state will unpause the GC
	ISPAUSED    = 10,
}

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	gc :: proc(L: ^State, what: i32, data: i32) -> i32 ---
}

CategoryName :: proc "c" (L: ^State, memcat: u8) -> cstring

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	// write a Luau memory dump to a FILE in JSON format
	// categoryName callback, when provided, will be called to record a name associated with the category
	memorydump :: proc(L: ^State, file: rawptr, categoryName: CategoryName) ---

	/*
	** memory statistics
	** all allocated bytes are attributed to the memory category of the running thread (0..LUA_MEMORY_CATEGORIES-1)
	*/
	setmemcat :: proc(L: ^State, category: i32) ---
	totalbytes :: proc(L: ^State, category: i32) -> c.size_t ---

	// measure the allocation rate in bytes/sec
	// returns -1 if allocation rate cannot be measured
	allocationrate :: proc(L: ^State) -> i64 ---

	/*
	** miscellaneous functions
	*/
	error :: proc(L: ^State) ---
	next :: proc(L: ^State, idx: i32) -> i32 ---
	rawiter :: proc(L: ^State, idx: i32, iter: i32) -> i32 ---
	concat :: proc(L: ^State, n: i32) ---
	setpointerencodekey :: proc(L: ^State, a: u64, b: u64, _c: u64, d: u64) ---
	encodepointer :: proc(L: ^State, p: c.uintptr_t) -> c.uintptr_t ---
	clock :: proc() -> f64 ---
	setuserdatatag :: proc(L: ^State, idx: i32, tag: i32) ---
	setuserdatadtor :: proc(L: ^State, tag: i32, dtor: Destructor) ---
	getuserdatadtor :: proc(L: ^State, tag: i32) -> Destructor ---
}

// Embedder GC integration APIs
//
// Luau -> embedder (lua_setuserdatamark): when the GC marks a tagged userdata,
// the registered callback fires so the embedder can mark the corresponding
// native object as reachable.
//
// Embedder -> Luau (lua_setembeddergc): the GC calls this each cycle.
// Two cases:
// 1. Cycle reset (markref == NULL): clear accumulated information about marked
//      native objects.
// 2. Mark phase (markref != NULL): embedder must call markref for each new ref
//      that is reachable from a marked native object and return nonzero if it
//      made any progress. The GC propagates marks and repeatedly calls again
//      until the embedder returns zero.
//
// Together, these are used to implement a fixed-point reachability algorithm
// across both heaps.
//
// Note: because these functions are called during garbage collection, they
// must not perform any reentrant operations on the lua_State. Only truly
// read-only APIs like lua_getthreaddata are safe to call from here.
UserdataMark :: proc "c" (L: ^State, ud: rawptr)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	setuserdatamark :: proc(L: ^State, tag: i32, markfn: UserdataMark) ---
}

EmbedderMark :: proc "c" (L: ^State, ref: i32)
EmbedderGc :: proc "c" (L: ^State, markref: EmbedderMark) -> i32

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	setembeddergc :: proc(L: ^State, fn: EmbedderGc) ---

	// APIs for interacting with embedder-managed weak references.
	//
	// Unlike lua_ref, these do not prevent collection on their own; the embedder
	// must call markref(L, ref) inside lua_EmbedderGc to keep them alive. If the
	// lua_getweakref API returns nil when the embedder expects the object to be
	// alive, it indicates a bug in the embedder's logic.
	//
	// Bugs in the embedder's marking logic can manifest in two ways:
	// - the native object owning a ref was not marked (Luau -> embedder), or
	// - if the native object was marked, the ref was not marked (embedder -> Luau).
	//
	// Otherwise, a non-marking-related bug could simply be that the embedder is
	// trying to access a ref that was correctly collected. Specifically, if a
	// native object that logically owns a ref is destroyed, then the embedder
	// should not be trying to access that ref anymore.
	//
	// In any case, asserting on the return value of lua_getweakref is a good way
	// for embedders to catch bugs in their own marking logic.
	weakref :: proc(L: ^State, idx: i32) -> i32 ---
	weakunref :: proc(L: ^State, ref: i32) -> i32 ---
	getweakref :: proc(L: ^State, ref: i32) -> i32 --- // returns the type of the value pushed onto the stack

	// alternative access for userdata metatables
	// used by lua_newuserdatataggedwithmetatable to create tagged userdata with the associated metatable assigned
	setuserdatametatable :: proc(L: ^State, tag: i32) ---
	getuserdatametatable :: proc(L: ^State, tag: i32) ---

	// Returns the name of a userdata tag - `__type` from the metatable or "userdata" if it is not set
	getuserdataname :: proc(L: ^State, tag: i32) -> cstring ---
}

// NOTE: experimental API and is subject to breaking changes
// registration of callbacks for direct userdata __index, __newindex and __namecall access with string keys assigned with an atom
// cachedslot is initially 0 and can be set to a custom value to help with data lookup inside the userdata
// IMPORTANT: cachedslot values are shared between all userdata, callbacks function of one userdata tag has to correctly handle values set by another
UserdataDirectAccess :: proc "c" (L: ^State, data: rawptr, atom: i32, cachedslot: ^u16, utag: i32)
UserdataDirectNamecall :: proc "c" (
	L: ^State,
	data: rawptr,
	atom: i32,
	cachedslot: ^u16,
	utag: i32,
) -> i32

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	registeruserdatadirectaccess :: proc(L: ^State, tag: i32, get: UserdataDirectAccess, set: UserdataDirectAccess, namecall: UserdataDirectNamecall) -> i32 ---
}

/*
** Direct field API
**
** lua_registeruserdatadirectfieldget registers a per-field, per-userdata-type
** handler that is invoked directly without allocating a Luau call frame.
**
** tag:   userdata tag (0..LUA_UTAG_LIMIT-1)
** field: field name string (will be interned and pinned)
** fn:    handler — receives raw userdata data pointer and result TValue slot
*/
UserdataDirectFieldGet :: proc "c" (ud: rawptr, result: rawptr)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	registeruserdatadirectfieldget :: proc(L: ^State, tag: i32, field: cstring, fn: UserdataDirectFieldGet) ---

	// Helpers for writing result values from a direct field handler.
	userdatadirectfield_setnumber :: proc(result: rawptr, n: f64) ---
	userdatadirectfield_setvector :: proc(result: rawptr, x: f32, y: f32, z: f32) ---
	userdatadirectfield_setboolean :: proc(result: rawptr, b: i32) ---
	userdatadirectfield_setinteger64 :: proc(result: rawptr, n: i64) ---
	userdatadirectfield_setnil :: proc(result: rawptr) ---
	setlightuserdataname :: proc(L: ^State, tag: i32, name: cstring) ---
	getlightuserdataname :: proc(L: ^State, tag: i32) -> cstring ---
	clonefunction :: proc(L: ^State, idx: i32) ---
	usesexport :: proc(L: ^State, idx: i32) -> i32 ---
	cleartable :: proc(L: ^State, idx: i32) ---
	clonetable :: proc(L: ^State, idx: i32) ---
	getallocf :: proc(L: ^State, ud: ^rawptr) -> Alloc ---
}

/*
** reference system, can be used to pin objects
*/
NOREF :: -1
REFNIL :: 0

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	ref :: proc(L: ^State, idx: i32) -> i32 ---
	unref :: proc(L: ^State, ref: i32) -> i32 ---
}

// Functions to be called by the debugger in specific events
Hook :: proc "c" (L: ^State, ar: ^Debug)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	// invoke a debug hook on a thread in break/yield state
	// userdata is passed to hook through lua_Debug::userdata field
	callhook :: proc(L: ^State, hook: Hook, userdata: rawptr) ---
	stackdepth :: proc(L: ^State) -> i32 ---
	getinfo :: proc(L: ^State, level: i32, what: cstring, ar: ^Debug) -> i32 ---
	getargument :: proc(L: ^State, level: i32, n: i32) -> i32 ---
	getlocal :: proc(L: ^State, level: i32, n: i32) -> cstring ---
	setlocal :: proc(L: ^State, level: i32, n: i32) -> cstring ---
	getupvalue :: proc(L: ^State, funcindex: i32, n: i32) -> cstring ---
	setupvalue :: proc(L: ^State, funcindex: i32, n: i32) -> cstring ---
	hascustomexecution :: proc(L: ^State, level: i32) -> i32 --- // function has custom execution data set
	incustomexecution :: proc(L: ^State, level: i32) -> i32 --- // function is running using custom execution
	singlestep :: proc(L: ^State, enabled: i32) ---
	breakpoint :: proc(L: ^State, funcindex: i32, line: i32, enabled: i32) -> i32 ---

	// returns 1 if execution is currently at a breakpoint; should only be called from debug callbacks
	atbreakpoint :: proc(L: ^State) -> i32 ---

	// Warning: this function is not thread-safe since it stores the result in a shared global array! Only use for debugging.
	debugtrace :: proc(L: ^State) -> cstring ---
}

Debug :: struct {
	name:        cstring, // (n)
	what:        cstring, // (s) `Lua', `C', `main', `tail'
	source:      cstring, // (s)
	short_src:   cstring, // (s)
	linedefined: i32, // (s)
	currentline: i32, // (l)
	protoid:     i32, // (p) globally unique (within VM) proto id; 0 for C functions
	bytecodeid:  i32, // (p) proto index within its bytecode module; -1 for C functions
	nupvals:     u8, // (u) number of upvalues
	nparams:     u8, // (a) number of parameters
	isvararg:    i8, // (a)
	userdata:    rawptr, // only valid in lua_callhook
	ssbuf:       [256]i8,
}

Coverage :: proc "c" (
	_context: rawptr,
	function: cstring,
	linedefined: i32,
	depth: i32,
	hits: ^i32,
	size: c.size_t,
)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	getcoverage :: proc(L: ^State, funcindex: i32, _context: rawptr, callback: Coverage) ---
}

CounterFunction :: proc "c" (_context: rawptr, function: cstring, linedefined: i32)
CounterValue :: proc "c" (_context: rawptr, kind: i32, line: i32, hits: u64)

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	// Unlike 'lua_getcoverage', counters are customizable in ways which prevent merging them together
	// 'lua_getcounters' will visit the specified function and all nested functions
	// 'functionvisit' is called first to establish a function, then multiple calls of 'countervisit' are made for each counter in that function
	getcounters :: proc(L: ^State, funcindex: i32, _context: rawptr, functionvisit: CounterFunction, countervisit: CounterValue) ---
}

/* Callbacks that can be used to reconfigure behavior of the VM dynamically.
* These are shared between all coroutines.
*
* Note: interrupt is safe to set from an arbitrary thread but all other callbacks
* can only be changed when the VM is not running any code */
Callbacks :: struct {
	userdata:            rawptr, // arbitrary userdata pointer that is never overwritten by Luau
	interrupt:           proc "c" (L: ^State, gc: i32), // gets called at safepoints (loop back edges, call/ret, gc) if set
	panic:               proc "c" (L: ^State, errcode: i32), // gets called when an unprotected error is raised (if longjmp is used)
	userthread:          proc "c" (LP: ^State, L: ^State), // gets called when L is created (LP == parent) or destroyed (LP == NULL)
	useratom:            proc "c" (L: ^State, s: cstring, l: c.size_t) -> i16, // gets called when a string is created to assign an atom id

	// NOTE: experimental API, requires a Debug flag to be called and is subject to breaking changes
	userfinalizer:       proc "c" (L: ^State, co: ^State), // gets called before a finalizer is attached to 'co' by current thread
	debugbreak:          proc "c" (L: ^State, ar: ^Debug), // gets called when BREAK instruction is encountered
	debugstep:           proc "c" (L: ^State, ar: ^Debug), // gets called after each instruction in single step mode
	debuginterrupt:      proc "c" (L: ^State, ar: ^Debug), // gets called when thread execution is interrupted by break in another thread
	debugprotectederror: proc "c" (L: ^State), // gets called when protected call results in an error

	// gets called after a heap object (or array) is allocated
	onallocate:          proc "c" (
		L: ^State,
		block: rawptr,
		osize: c.size_t,
		nsize: c.size_t,
		memcat: u8,
		tt: i32,
		tag: i32,
	),
	preresume:           proc "c" (L: ^State), // gets called before lua_resume runs a (co)routine
	postresume:          proc "c" (L: ^State), // gets called after lua_resume returns (yield, return, or error)

	// gets called before a heap object (or array) is freed
	onfree:              proc "c" (L: ^State, block: rawptr),
}

@(default_calling_convention = "c", link_prefix = "lua_")
foreign LuauVM {
	callbacks :: proc(L: ^State) -> ^Callbacks ---

	// Must be called after lua_newstate and before the state creates any additional objects
	// The VM makes no assumptions about the layout or structure of the caged heap
	// The VM does assume that the embedder will free any memory allocated if the main lua_State the cage is associated with is closed
	setmemorycage :: proc(L: ^State, alloc: CageAlloc, ud: rawptr) ---
}
