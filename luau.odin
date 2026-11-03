// This file is part of the Luau programming language and is licensed under MIT License; see LICENSE.txt for details
package luau

import "core:c"

when ODIN_OS == .Windows {
	@(extra_linker_flags = "/NODEFAULTLIB:libcmtd")
	foreign import LuauCompiler {"./lib/windows/Luau.Compiler.lib", "./lib/windows/Luau.AST.lib", "./lib/windows/Luau.Bytecode.lib", "./lib/windows/Luau.Common.lib"}
} else {
	#panic("Unsupported OS(currently). If you want, make a PR with the compiled binaries for your OS.")
}

CompileConstant :: rawptr

// return a type identifier for a global library member
// values are defined by 'enum LuauBytecodeType' in Bytecode.h
LibraryMemberTypeCallback :: proc "c" (library: cstring, member: cstring) -> i32

// setup a value of a constant for a global library member
// use luau_set_compile_constant_*** set of functions for values
LibraryMemberConstantCallback :: proc "c" (
	library: cstring,
	member: cstring,
	constant: ^CompileConstant,
)

CompileOptions :: struct {
	// 0 - no optimization
	// 1 - baseline optimization level that doesn't prevent debuggability
	// 2 - includes optimizations that harm debuggability such as inlining
	optimization_level:           i32, // default=1

	// 0 - no debugging support
	// 1 - line info & function names only; sufficient for backtraces
	// 2 - full debug info with local & upvalue names; necessary for debugger
	debug_level:                  i32, // default=1

	// type information is used to guide native code generation decisions
	// information includes testable types for function arguments, locals, upvalues and some temporaries
	// 0 - generate for native modules
	// 1 - generate for all modules
	type_info_level:              i32, // default=0

	// 0 - no code coverage support
	// 1 - statement coverage
	// 2 - statement and expression coverage (verbose)
	coverage_level:               i32, // default=0

	// alternative global builtin to construct vectors, in addition to default builtin 'vector.create'
	vector_lib:                   cstring,
	vector_ctor:                  cstring,

	// alternative vector type name for type tables, in addition to default type 'vector'
	vector_type:                  cstring,

	// 0 - 32-bit float vector components
	// 1 - 64-bit double vector components
	vector_precision:             i32, // default=0

	// null-terminated array of globals that are mutable; disables the import optimization for fields accessed through these
	mutable_globals:              ^cstring,

	// null-terminated array of userdata types that will be included in the type information
	userdata_types:               ^cstring,

	// null-terminated array of globals which act as libraries and have members with known type and/or constant value
	// when an import of one of these libraries is accessed, callbacks below will be called to receive that information
	libraries_with_known_members: ^cstring,
	library_member_type_cb:       LibraryMemberTypeCallback,
	library_member_constant_cb:   LibraryMemberConstantCallback,

	// null-terminated array of library functions that should not be compiled into a built-in fastcall ("name" "lib.name")
	disabled_builtins:            ^cstring,
}

@(default_calling_convention = "c", link_prefix = "luau_")
foreign LuauCompiler {
	// compile source to bytecode; when source compilation fails, the resulting bytecode contains the encoded error. use free() to destroy
	compile :: proc(source: cstring, size: c.size_t, options: ^CompileOptions, outsize: ^c.size_t) -> cstring --- // luau_compile

	// when libraryMemberConstantCb is called, these methods can be used to set a value of the opaque lua_CompileConstant struct
	// vector component 'w' is not visible to VM runtime configured with LUA_VECTOR_SIZE == 3, but can affect constant folding during compilation
	// string storage must outlive the invocation of 'luau_compile' which used the callback
	set_compile_constant_nil :: proc(constant: ^CompileConstant) --- // luau_set_compile_constant_nil
	set_compile_constant_boolean :: proc(constant: ^CompileConstant, b: i32) --- // luau_set_compile_constant_boolean
	set_compile_constant_number :: proc(constant: ^CompileConstant, n: f64) --- // luau_set_compile_constant_number
	set_compile_constant_integer64 :: proc(constant: ^CompileConstant, l: i64) --- // luau_set_compile_constant_integer64
	set_compile_constant_vector :: proc(constant: ^CompileConstant, x: f32, y: f32, z: f32, w: f32) --- // luau_set_compile_constant_vector
	set_compile_constant_vectord :: proc(constant: ^CompileConstant, x: f64, y: f64, z: f64, w: f64) --- // luau_set_compile_constant_vectord
	set_compile_constant_string :: proc(constant: ^CompileConstant, s: cstring, l: c.size_t) --- // luau_set_compile_constant_string
}
