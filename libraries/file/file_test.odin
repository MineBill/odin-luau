package luau_file
import "../../../luau"
import "../../lua"
import "../../luaL"
import test "core:testing"
import "core:os"
import "core:sys/windows"

test_compile_options := luau.CompileOptions {
    optimization_level = 1,
    debug_level = 1,
    type_info_level = 0,
    coverage_level = 1,
}

TEST_ROOT :: "luau/libraries/file"

// Compiles a Luau script and returns the size of the compile bytecode.
compile_script :: proc(t: ^test.T, L: ^lua.State, $path: string) {
    source := #load(path, cstring)
    size: uint
    bytecode := luau.compile(source, len(source), &test_compile_options, &size)
    luaL.open_base(L)
    luaL.open_string(L)

    lua.pushstring(L, TEST_ROOT)
    lua.setglobal(L, "TEST_ROOT")

    if lua.load(L, "=test", bytecode, size, 0) != .OK {
        error := lua.tostring(L, -1)
        test.fail_now(t, error)
    }
    return
}

@(test)
z_cleanup :: proc(t: ^test.T) {
    test.cleanup(t, proc(t: rawptr) {
        t := cast(^test.T) t
        if ODIN_OS == .Windows {
            name := windows.utf8_to_wstring(TEST_ROOT + "/temp")
            op := windows.SHFILEOPSTRUCTW {
                hwnd = nil,
                wFunc = windows.FO_DELETE,
                pFrom = name,
                pTo = nil,
                fFlags = windows.FOF_NOCONFIRMATION | windows.FOF_NOERRORUI | windows.FOF_SILENT,
                fAnyOperationsAborted = false,
                hNameMappings = nil,
                lpszProgressTitle = nil,
            }
            windows.SHFileOperationW(&op)
        } else {
            errno := os.remove_directory(TEST_ROOT + "/temp")
            if errno != 0 {
                test.logf(t, "errno: %v", errno)
            }
        }
    }, t)
}

@(test)
read_entire_file_test :: proc(t: ^test.T) {
    L := luaL.newstate()
    defer lua.close(L)
    openlib(L, "fs")

    compile_script(t, L, "tests/read_file_test.luau")

    if lua.pcall(L, 0, 1, 0) != .OK {
        error := lua.tostring(L, -1)
        test.fail_now(t, error)
    }

    file_txt := lua.tostring(L, -1)
    FILE_DOT_ODIN :: #load("file.odin", string)
    test.expect(t, file_txt == FILE_DOT_ODIN, file_txt)

    test.expect(t, true, "pepegas")
}

@(test)
file_write_test :: proc(t: ^test.T) {
    L := luaL.newstate()
    defer lua.close(L)
    openlib(L, "fs")

    compile_script(t, L, "tests/file_write_test.luau")

    if lua.pcall(L, 0, 0, 0) != .OK {
        error := lua.tostring(L, -1)
        test.fail_now(t, error)
    }

    file, _ := os.read_entire_file(TEST_ROOT + "/temp/test.txt")

    LINE :: "This is a line from luau!"
    test.expect_value(t, string(file), LINE)
}
