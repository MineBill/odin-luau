type FileMode = "r" | "w" | "rw" | "a"

declare fs: {
    read_entire_file: (file_name: string) -> (string),
    open: (file_name: string, mode: FileMode) -> (FileHandle),
}

declare class FileHandle
    function path(self): string
    function read(self, size: number): buffer
    function write(self, data: buffer | string)
end