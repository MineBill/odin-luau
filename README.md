# Luau Bindings for Odin

This repo contains bindings for the [Luau](https://luau-lang.org) programming language.

> [!WARNING]
> Currently, the binaries are bundled and only for Windows. I plan to include a small build script to pull the Luau repo and build it directly.
In the meantime, if you want to build them yourself, you need to clone Luau, and configure it with the following flags: `-DLUAU_EXTERN_C=1` and `-DLUAU_STATIC_CRT=1`.

## Usage
Most of the Lua API stays to same excect some missing procs here and there.
Make sure to read the differences between Luau and Lua [here](https://luau-lang.org/compatibility).

The biggest differnce is loading a file. Luau does not have a loadfile function and requires compilation
before executing a piece of code.

Here is a simple `main.odin` that reads a file, compiles it and then executes it:
```odin
package main
import "core:os"
import "luau"
import "luau/lua"
import "luau/luaL"

main :: proc() {
    // You can see what these do in `luau.odin`. All of the original comments
    // are left untouched.
    options := luau.CompileOptions {
        optimization_level = 1,
        debug_level = 1,
        type_info_level = 0,
        coverage_level = 0,
    }

    source, _ := os.read_entire_file("main.luau")

    out_size: c.size_t
    code := luau.compile(cstr(string(source)), len(source), &options, &out_size)

    L := luaL.newstate()
    luaL.openlibs(L) // Makes the `print` function available.
    lua.load(L, "module", code, out_size, 0)
    lua.call(L, 0, 0)
}
```

## Some notes
Luau, for the most part, follows the original Lua api and as such you can use the 5.1 [reference manual](https://www.lua.org/manual/5.1/manual.html) to figure out what each proc does.

However, some of it has changed (some procs have a return value when the don't in Lua) and there are a few extra procs. Since these are not documented anywhere, your best best is to just read the tests in the Luau repo.