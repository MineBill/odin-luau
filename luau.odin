package luau
import "core:c"

when ODIN_OS == .Windows {
    foreign import LuauVM {
        "./lib/Luau.VM.lib",
    }

    @(extra_linker_flags="/NODEFAULTLIB:libcmtd")
    foreign import LuauCompiler {
        "./lib/Luau.Compiler.lib",
        "./lib/Luau.AST.lib",
        "./lib/Luau.CLI.lib.lib",
    }
}

CompileOptions :: struct {
    // 0 - no optimization
    // 1 - baseline optimization level that doesn't prevent debuggability
    // 2 - includes optimizations that harm debuggability such as inlining
    optimization_level: i32, // default=1

    // 0 - no debugging support
    // 1 - line info & function names only; sufficient for backtraces
    // 2 - full debug info with local & upvalue names; necessary for debugger
    debug_level: i32, // default=1

    // type information is used to guide native code generation decisions
    // information includes testable types for function arguments, locals, upvalues and some temporaries
    // 0 - generate for native modules
    // 1 - generate for all modules
    type_info_level: i32, // default=0

    // 0 - no code coverage support
    // 1 - statement coverage
    // 2 - statement and expression coverage (verbose)
    coverage_level: i32, // default=0

    // global builtin to construct vectors; disabled by default
    vector_lib: cstring,
    vector_ctor: cstring,

    // vector type name for type tables; disabled by default
    vector_type: cstring,

    // null-terminated array of globals that are mutable; disables the import optimization for fields accessed through these
    mutable_globals: [^]cstring,
}

@(link_prefix="luau_")
foreign LuauCompiler {

    // compile source to bytecode; when source compilation fails, the resulting bytecode contains the encoded error. use free() to destroy
    compile :: proc(source: cstring, size: c.size_t, options: ^CompileOptions, out_size: ^c.size_t) -> cstring ---
}