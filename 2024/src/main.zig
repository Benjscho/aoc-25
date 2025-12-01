const std = @import("std");
const clap = @import("clap");
const _2024 = @import("_2024");

pub fn main() !void {
    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`.
    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-d, --day <usize>      Day of AoC to run
        \\<str>...
        \\
    );

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = std.heap.page_allocator,
    }) catch |err| {
        // Report useful error and exit.
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});

    if (res.args.day == 1)
        try day_one();
    if (res.args.day == 2)
        try day_two();
}

fn day_one() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {
        fn parse_line(line: []u8) ![2]i32 {
            var split_iter = std.mem.splitSequence(u8, line, "   ");
            const a = try std.fmt.parseInt(i32, split_iter.next().?, 10);
            const b = try std.fmt.parseInt(i32, split_iter.next().?, 10);
            return .{ a, b };
        }
    };

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
        const res = L.parse_line(line.written()) catch {
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

fn day_two() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {
        fn parse_line(line: []u8) !std.ArrayListUnmanaged(i32) {
            var split_iter = std.mem.splitSequence(u8, line, " ");
            var nums: std.ArrayListUnmanaged(i32) = .{};

            while (split_iter.next()) |v| {
                const a = try std.fmt.parseInt(i32, v, 10);
                try nums.append(alloc, a);
            }
            return nums;
        }

        fn is_safe(line: []i32) bool {
            const direction = (line[1] - line[0]) > 0;
            var i: u32 = 1;
            while (i < line.len) {
                const diff = line[i] - line[i - 1];
                const curr_dirr = diff > 0;
                if (@abs(diff) < 1 or @abs(diff) > 3 or direction != curr_dirr)
                    return false;
                i += 1;
            }
            return true;
        }
    };

    const file = try std.fs.cwd().openFile(
        "day-2-input.txt",
        .{},
    );
    defer file.close();
    var read_buf: [1024]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);

    const reader = &file_reader.interface;
    var line = std.Io.Writer.Allocating.init(alloc);
    defer line.deinit();

    var reports: std.ArrayListUnmanaged(*std.ArrayListUnmanaged(i32)) = .{};
    var pt1_res: u32 = 0;
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        var level = L.parse_line(line.written()) catch {
            break;
        };
        try reports.append(alloc, &level);
        if (L.is_safe(level.items))
            pt1_res += 1;

        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }

    std.debug.print("part 1 result is {d}\n", .{pt1_res});
}
