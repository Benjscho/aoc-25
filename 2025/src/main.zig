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
