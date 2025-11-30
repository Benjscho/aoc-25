const std = @import("std");
const _2024 = @import("_2024");

pub fn main() !void {
    const alloc = std.heap.page_allocator;

    const file = try std.fs.cwd().openFile(
        "day-1-input.txt",
        .{},
    );
    defer file.close();
    var read_buf: [1024]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);

    const reader = &file_reader.interface;
    var line = std.Io.Writer.Allocating.init(alloc);
    defer line.deinit();

    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const res = parse_line(line.written()) catch {
            break;
        };
        std.debug.print("sum is: {d}\n", .{res[0] + res[1]});
        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }
}

fn parse_line(line: []u8) ![2]i32 {
    var split_iter = std.mem.splitSequence(u8, line, "   ");
    const a = try std.fmt.parseInt(i32, split_iter.next().?, 10);
    const b = try std.fmt.parseInt(i32, split_iter.next().?, 10);
    return .{ a, b };
}
