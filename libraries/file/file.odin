package luau_file
import "core:os"
import "core:strings"
import "base:runtime"
import "core:path/filepath"

import "../../lua"
import "../../luaL"

// File API for Luau:
// Luau does not have a file api and the reason cited is "security". That makes
// sense in the context of Roblox but as this is a generic binding for general usage
// a file "module" has to be created by you. Since i'm going to be using this library
// and want a file "module" for myself, i thought i could include it in this library
// for you to use aswell.

File :: struct {
    handle: os.Handle,
    closed: bool,

    path: string,
}

methods := []luaL.Reg {
    { name = "path", func = file_path },
    { name = "read", func = file_read },
    { name = "write", func = file_write },
    {},
}

openlib :: proc(L: ^lua.State, name: string) {
    funcs := []luaL.Reg {
        { name = "read_entire_file", func = read_entire_file },
        { name = "open", func = open },
        {},
    }

    luaL.newmetatable(L, "file.FileHandle")
    lua.pushstring(L, "__index")
    lua.pushvalue(L, -2)
    lua.settable(L, -3)

    luaL.register(L, nil, raw_data(methods))

    luaL.register(L, cstr(name), raw_data(funcs))
}

read_entire_file :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if !lua.isstring(L, -1) {
        lua.pushnil(L)
        return 0
    }
    file_name := lua.tostring(L, -1)

    file, ok := os.read_entire_file(file_name)
    if !ok {
        lua.pushnil(L)
        return 0
    }

    lua.pushlstring(L, strings.unsafe_string_to_cstring(string(file)), len(file))
    return 1
}

open :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    luaL.argcheck(L, cast(bool) lua.isstring(L, -2), 1, "Expected a path")
    luaL.argcheck(L, cast(bool) lua.isstring(L, -1), 2, "Expected a file mode")

    file_name := lua.tostring(L, -2)
    mode := lua.tostring(L, -1)
    _ = mode

    base_dir := filepath.dir(file_name)
    defer delete(base_dir)

    make_directory_recursive(base_dir)
    handle, err := os.open(file_name, os.O_RDWR | os.O_CREATE)
    if err != 0 {
        lua.pushnil(L)
        return 0
    }

    file := cast(^File) lua.newuserdatadtor(L, size_of(File), file_dtor)
    file.handle = handle
    file.path = strings.clone(file_name)

    luaL.getmetatable(L, "file.FileHandle")
    lua.setmetatable(L, -2)
    return 1
}

close :: proc "c" (L: ^lua.State) -> i32 {
    context = runtime.default_context()
    if !lua.isnumber(L, -1) {
        lua.pushnil(L)
        return 0
    }
    handle := cast(os.Handle) lua.tointeger(L, -1)

    os.close(handle)
    return 1
}

file_read :: proc"c"(L: ^lua.State) -> i32 {
    file := check_file(L)
    size := luaL.checkinteger(L, 2)
    context = runtime.default_context()

    data := cast([^]byte) lua.newbuffer(L, cast(uint) size)

    os.read(file.handle, data[:size])

    // os.read()
    return 1
}

file_write :: proc"c"(L: ^lua.State) -> i32 {
    file := check_file(L)
    size: uint
    data := cast([^]byte) lua.tobuffer(L, 2, &size)
    s_size: uint
    s := lua.tolstring(L, 2, &s_size)

    luaL.argcheck(L, data != nil || s != nil, 2, "Expected a buffer or a string")
    context = runtime.default_context()
    if data != nil {
        os.write(file.handle, data[:size])
    } else if s != nil {
        os.write_string(file.handle, string(s))
    }



    return 1
}

file_path :: proc"c"(L: ^lua.State) -> i32 {
    file := check_file(L)
    context = runtime.default_context()

    lua.pushstring(L, cstr(file.path))

    return 1
}

cstr :: proc(s: string) -> cstring {
    return strings.clone_to_cstring(s, context.temp_allocator)
}

file_dtor :: proc"c"(data: rawptr) {
    context = runtime.default_context()
    file := cast(^File) data
    if file.closed {
        return
    }
    os.close(file.handle)
    file.closed = true
}

check_file :: proc"c"(L: ^lua.State) -> ^File {
    file := luaL.checkudata(L, 1, "file.FileHandle")
    luaL.argcheck(L, file != nil, 1, "'file' expected")
    return cast(^File) file
}

make_directory_recursive :: proc(p: string) {
    path, _ := strings.clone(p, context.temp_allocator)
    defer free_all(context.temp_allocator)

    temp: string
    for dir in strings.split_iterator(&path, "/") {
        temp = strings.join({temp, dir, "/"}, "", context.temp_allocator)
        os.make_directory(temp)
    }
}
