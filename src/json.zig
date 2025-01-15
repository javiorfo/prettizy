const std = @import("std");
const util = @import("util.zig");
const testing = std.testing;

pub const isFormatted = util.isFormatted;

/// Prettifies the given JSON string using the provided options.
///
/// @param allocator The memory allocator to use for the resulting string (ArenaAllocator recommended).
/// @param json_string The input JSON string to prettify.
/// @param pretty_options The options to use for pretty-printing.
/// @return The prettified JSON string, or an error if the operation fails.
pub fn prettify(allocator: std.mem.Allocator, json_string: []const u8, pretty_options: util.PrettyOptions) ![]const u8 {
    const max_pretty_length = json_string.len * pretty_options.multiply_max_length;
    var pretty_json = try allocator.alloc(u8, max_pretty_length);
    defer allocator.free(pretty_json);

    var indent: usize = 0;
    var in_string: bool = false;
    var index: usize = 0;

    for (json_string) |c| {
        switch (c) {
            '\"' => {
                in_string = !in_string;
                pretty_json[index] = c;
                index += 1;
            },
            '{', '[' => {
                pretty_json[index] = c;
                index += 1;
                if (!in_string) {
                    pretty_json[index] = '\n';
                    index += 1;
                    indent += 1;
                    addSpaces(indent, pretty_options.tab_space, pretty_json, &index);
                }
            },
            '}', ']' => {
                if (!in_string) {
                    pretty_json[index] = '\n';
                    index += 1;
                    indent -= 1;
                    addSpaces(indent, pretty_options.tab_space, pretty_json, &index);
                }
                pretty_json[index] = c;
                index += 1;
            },
            ',' => {
                pretty_json[index] = c;
                index += 1;
                if (!in_string) {
                    pretty_json[index] = '\n';
                    index += 1;
                    addSpaces(indent, pretty_options.tab_space, pretty_json, &index);
                }
            },
            ' ' => {
                if (in_string) {
                    pretty_json[index] = c;
                    index += 1;
                }
            },
            ':' => {
                pretty_json[index] = c;
                index += 1;
                if (!in_string) {
                    pretty_json[index] = ' ';
                    index += 1;
                }
            },
            else => {
                pretty_json[index] = c;
                index += 1;
            },
        }
    }
    pretty_json[index] = '0';

    return try std.mem.Allocator.dupe(allocator, u8, pretty_json[0..index]);
}

/// Adds the specified number of spaces to the pretty-printed JSON string.
///
/// @param indent The number of indentation levels to add.
/// @param tab_space The number of spaces to use for each indentation level.
/// @param pretty_json The mutable pretty-printed JSON string.
/// @param index The current index in the `pretty_json` string, which will be updated.
fn addSpaces(indent: usize, tab_space: usize, pretty_json: []u8, index: *usize) void {
    for (indent) |_| {
        for (tab_space) |_| {
            pretty_json[index.*] = ' ';
            index.* += 1;
        }
    }
}

test "json" {
    const allocator = testing.allocator;
    const json_string = "{\"name\":\"John\",\"age\":30,\"city\":\"New York\",\"hobbies\":[\"reading\",\"traveling\"], \"obj\":{\"field\":[1,2]}}";
    const prettified_json = try prettify(allocator, json_string, .{ .tab_space = 4 });
    defer allocator.free(prettified_json);
    const resp =
        \\{
        \\    "name": "John",
        \\    "age": 30,
        \\    "city": "New York",
        \\    "hobbies": [
        \\        "reading",
        \\        "traveling"
        \\    ],
        \\    "obj": {
        \\        "field": [
        \\            1,
        \\            2
        \\        ]
        \\    }
        \\}
    ;

    try testing.expectEqualStrings(prettified_json, resp);
}
