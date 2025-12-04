const std = @import("std");
const clap = @import("clap");
const _2024 = @import("_2024");

pub fn main() !void {
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
    if (res.args.day == 3)
        try day_three();
    if (res.args.day == 4)
        try day_four();
}

fn day_one() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {
        fn parse_line(line: []u8) !i32 {
            const mod: i32 = if (line[0] == 'L') -1 else 1;
            const val: i32 = try std.fmt.parseInt(i32, line[1..], 10);
            //std.debug.print("move: {any}, parsed: {any}\n", .{ line, mod * val });
            return mod * val;
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

    var pt1_res: u32 = 0;
    var pt2_res: u32 = 0;
    var dial_pos: i32 = 50;
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const res = L.parse_line(line.written()) catch {
            break;
        };
        dial_pos = @mod(dial_pos + res, 100);
        if (dial_pos == 0)
            pt1_res += 1;
        pt2_res += @divFloor(@abs(res), 100);
        if (res > 0 and dial_pos < (@mod(res, 100)) and dial_pos != 0)
            pt2_res += 1;
        if (res < 0 and dial_pos > 100 - (@abs(res) % 100))
            pt2_res += 1;

        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }
    pt2_res += pt1_res;

    std.debug.print("part 1 result is {d}\n", .{pt1_res});
    std.debug.print("part 2 result is {d}\n", .{pt2_res});
}

fn day_two() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {
        fn parse_id_range(range: []u8) ![2]usize {
            var it = std.mem.splitSequence(u8, range, "-");
            const start = try std.fmt.parseInt(usize, it.next().?, 10);
            const end = try std.fmt.parseInt(usize, it.next().?, 10);
            std.debug.print("parsed {d} {d}\n", .{ start, end });
            return .{ start, end };
        }

        fn is_invalid(num: usize) !bool {
            var b: [26]u8 = undefined;
            const str = try std.fmt.bufPrint(&b, "{d}", .{num});
            //std.debug.print("formatted {s}\n", .{str});
            if (str.len % 2 == 1)
                return false;
            const split = str.len / 2;
            if (std.mem.eql(u8, str[0..split], str[split..])) {
                return true;
            } else {
                return false;
            }
        }

        fn is_invalid_n_reps(num: usize) !bool {
            var b: [26]u8 = undefined;
            const str = try std.fmt.bufPrint(&b, "{d}", .{num});
            //std.debug.print("formatted {s}\n", .{str});
            var i: usize = 0;
            while (i < str.len / 2) {
                var j = i + 1;
                var valid = false;
                const step = j;
                while (j < str.len and !valid) {
                    if (j + step > str.len) {
                        valid = true;
                        break;
                    }
                    //std.debug.print("checking {s} {s} \n", .{ str[0 .. i + 1], str[j .. j + step] });
                    if (!std.mem.eql(u8, str[0 .. i + 1], str[j .. j + step])) {
                        //std.debug.print("found mismatch, so valid {s} {s} \n", .{ str[0 .. i + 1], str[j .. j + step] });
                        valid = true;
                        break;
                    }
                    j += step;
                }
                if (!valid) {
                    //std.debug.print("Found invalid: {s} \n", .{str});
                    return true;
                }
                i += 1;
            }
            return false;
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

    var pt1_res: usize = 0;
    var pt2_res: usize = 0;
    while (true) {
        _ = reader.streamDelimiter(&line.writer, ',') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const res = L.parse_id_range(line.written()) catch {
            break;
        };

        var i = res[0];
        while (i <= res[1]) {
            if (try L.is_invalid(i))
                pt1_res += i;
            if (try L.is_invalid_n_reps(i))
                pt2_res += i;
            i += 1;
        }

        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }
    std.debug.print("part 1 result is {d}\n", .{pt1_res});
    std.debug.print("part 2 result is {d}\n", .{pt2_res});
}

fn day_three() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {
        const Pointer = struct {
            val: u8,
            pos: usize,
        };

        // Two pointers. Assumes that the line has >2 chars
        fn find_highest_num(line: []u8) !usize {
            var i = line.len - 2;
            var j = line.len - 1;
            var left: Pointer = .{ .val = line[i], .pos = i };
            var right: Pointer = .{ .val = line[j], .pos = j };

            while (i > 0) {
                i -= 1;
                if (line[i] >= left.val) {
                    left.val = line[i];
                    left.pos = i;
                }
            }
            while (j > left.pos + 1) {
                j -= 1;
                if (line[j] >= right.val) {
                    right.val = line[j];
                    right.pos = j;
                }
            }

            return try std.fmt.parseInt(usize, &.{ left.val, right.val }, 10);
        }

        // N pointers. This is essentially the same algorithm as above, except
        // we do it for 12 pointers instead of just 2
        fn find_highest_num_n(line: []u8) !usize {
            // n pointers
            const n = 12;
            var max_pointers: [n]Pointer = undefined;
            var pos_trackers: [n]usize = undefined;
            for (&max_pointers, 0..) |*ptr, i| {
                ptr.* = Pointer{ .val = line[line.len - n + i], .pos = line.len - n + i };
            }
            for (&pos_trackers, 0..) |*ptr, i| {
                ptr.* = line.len - n + i;
            }
            var start_num: [n]u8 = undefined;
            for (&start_num, 0..) |*ptr, i| {
                ptr.* = max_pointers[i].val;
            }
            std.debug.print("startnum {s}\n", .{start_num});

            var idx: usize = 0;
            // initial left bound
            var left_bound: i32 = -1;
            // Iterate over each of them
            std.debug.print("line: {s}\n", .{line});
            while (idx < n) {
                const ptr = &pos_trackers[idx];
                while (ptr.* > left_bound + 1) {
                    std.debug.print("idx: {d}, ptr: {d}, left_bound: {d}\n", .{ idx, ptr.*, left_bound });
                    ptr.* -= 1;
                    if (line[ptr.*] >= max_pointers[idx].val) {
                        max_pointers[idx].pos = ptr.*;
                        max_pointers[idx].val = line[ptr.*];
                    }
                }
                left_bound = @intCast(max_pointers[idx].pos);
                std.debug.print("mp val: {c}, pos: {d}\n", .{ max_pointers[idx].val, max_pointers[idx].pos });
                idx += 1;
            }
            var num: [n]u8 = undefined;
            for (&num, 0..) |*ptr, i| {
                ptr.* = max_pointers[i].val;
            }

            return try std.fmt.parseInt(usize, &num, 10);
        }
    };
    const file = try std.fs.cwd().openFile(
        "day-3-input.txt",
        .{},
    );
    defer file.close();
    var read_buf: [1024]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);

    const reader = &file_reader.interface;
    var line = std.Io.Writer.Allocating.init(alloc);
    defer line.deinit();

    var pt1_res: usize = 0;
    var pt2_res: usize = 0;
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const res = L.find_highest_num(line.written()) catch {
            break;
        };
        pt1_res += res;

        const res_2 = L.find_highest_num_n(line.written()) catch {
            break;
        };
        std.debug.print("Found max num: {d}\n", .{res_2});
        pt2_res += res_2;

        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }
    std.debug.print("part 1 result is {d}\n", .{pt1_res});
    std.debug.print("part 2 result is {d}\n", .{pt2_res});
}

// Nice classic grid search!
fn day_four() !void {
    const alloc = std.heap.page_allocator;

    const L = struct {

        // Two pointers. Assumes that the line has >2 chars
        fn find_highest_num(line: [][]u8) !usize {
            var res: usize = 0;
            const rows = line.len;
            const cols = line[0].len;
            for (0..rows) |y| {
                for (0..cols) |x| {
                    if (line[y][x] == '.') {
                        continue;
                    }
                    std.debug.print("found {c} at {d},{d}\n", .{ line[y][x], y, x });
                    var blocked: i64 = 0;
                    for (0..3) |dy| {
                        for (0..3) |dx| {
                            const ny = y + dy;
                            const nx = x + dx;
                            if (ny <= 0 or ny > rows or nx <= 0 or nx > cols or (dx == 1 and dy == 1)) {
                                continue;
                            }
                            std.debug.print("checking {d}{d}: {c}\n", .{ ny - 1, nx - 1, line[ny - 1][nx - 1] });
                            if (line[ny - 1][nx - 1] == '@') {
                                //std.debug.print("blocked\n", .{});
                                blocked += 1;
                            }
                        }
                    }
                    std.debug.print("{d},{d} has {} blocked \n", .{ y, x, blocked });
                    if (blocked < 4) {
                        res += 1;
                    }
                }
            }
            return res;
        }
    };
    const file = try std.fs.cwd().openFile(
        "day-4-input.txt",
        .{},
    );
    defer file.close();
    var read_buf: [1024]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&read_buf);

    const reader = &file_reader.interface;
    var line = std.Io.Writer.Allocating.init(alloc);
    defer line.deinit();

    var grid: std.ArrayListUnmanaged([]u8) = .{};
    while (true) {
        _ = reader.streamDelimiter(&line.writer, '\n') catch |err| {
            if (err == error.EndOfStream) break else return err;
        };
        _ = reader.toss(1); // skip the delimiter byte.
        const l = try alloc.dupe(u8, line.written());
        try grid.append(alloc, l);

        line.clearRetainingCapacity(); // reset the accumulating buffer.
    }
    const pt1_res: usize = try L.find_highest_num(grid.items);
    std.debug.print("part 1 result is {d}\n", .{pt1_res});
}
