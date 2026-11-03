// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
// This code is based on Lua 5.x implementation licensed under MIT License; see lua_LICENSE.txt for details
package lua_vm

// Can be used to reconfigure internal error handling to use longjmp instead of C++ EH
USE_LONGJMP :: 0

// LUA_IDSIZE gives the maximum size for the description of the source
IDSIZE :: 256

// LUA_MINSTACK is the initial number of reserved stack slots for a C function
MINSTACK :: 20

// LUAI_MAXCSTACK limits the number of Lua stack slots that a C function can use
MAXCSTACK :: 8000

// LUAI_MAXCALLS limits the number of nested calls
MAXCALLS :: 20000

// LUAI_MAXCCALLS is the maximum depth for nested C calls; this limit depends on native stack size
MAXCCALLS :: 200

// buffer size used for on-stack string operations; this limit depends on native stack size
BUFFERSIZE :: 512

// number of valid Lua userdata tags
UTAG_LIMIT :: 128

// number of valid Lua lightuserdata tags
LUTAG_LIMIT :: 128

// upper bound for number of size classes used by page allocator
SIZECLASSES :: 40

// available number of separate memory categories
MEMORY_CATEGORIES :: 256

// extra storage for execution callbacks in global state
EXECUTION_CALLBACK_STORAGE :: 512

// minimum size for the string table (must be power of 2)
MINSTRTABSIZE :: 32

// maximum number of captures supported by pattern matching
MAXCAPTURES :: 32

VECTOR_SIZE :: 3 // must be 3 or 4
VECTOR_DOUBLE :: 0
EXTRA_SIZE :: (VECTOR_SIZE - 2)
