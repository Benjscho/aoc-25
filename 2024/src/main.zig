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

    var left: std.ArrayListUnmanaged(i32) = .{};
    var right: std.ArrayListUnmanaged(i32) = .{};
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const res = parse_line(line.written()) catch {
            break;
        };
        try left.append(alloc, res[0]);
        try right.append(alloc, res[1]);
        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }

    std.mem.sort(i32, left.items, {}, std.sort.asc(i32));
    std.mem.sort(i32, right.items, {}, std.sort.asc(i32));

    var res: u32 = 0;
    for (left.items, right.items) |v1, v2| {
        res += @abs(v1 - v2);
    }
    std.debug.print("part 1 result is {d}\n", .{res});

    var right_map = std.AutoHashMap(i32, i32).init(alloc);
    for (right.items) |val| {
        const gop = try right_map.getOrPut(val);
        if (gop.found_existing) {
            gop.value_ptr.* += 1;
        } else {
            gop.value_ptr.* = 1;
        }
    }

    res = 0;
    for (left.items) |val| {
        const multiple = right_map.get(val) orelse 0;
        res += @intCast(val * multiple);
    }
    std.debug.print("part 2 result is {d}\n", .{res});
}

fn parse_line(line: []u8) ![2]i32 {
    var split_iter = std.mem.splitSequence(u8, line, "   ");
    const a = try std.fmt.parseInt(i32, split_iter.next().?, 10);
    const b = try std.fmt.parseInt(i32, split_iter.next().?, 10);
    return .{ a, b };
}
