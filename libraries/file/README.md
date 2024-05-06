# File
This simple library, exposes some of the `core:os` procs in Luau.

```go
import "luau/libraries/file"
...
file.openlib(L, name = "fs")
...
```

Then, in your Luau script you can do:
```lua
local text = fs.read_entire_file("path/to/file.txt")
-- and
local file = fs.open("file.txt", "rw")
print(file:read(10)) -- read 10 bytes, returns a buffer
file:write("Write some string")
```

## LSP Definition file
A `file.d.luau` definition file is provided to help you get autocompletion in your editor.
Requires [Luau-LSP](https://github.com/JohnnyMorganz/luau-lsp).