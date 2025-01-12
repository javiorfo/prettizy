const std = @import("std");

pub fn prettify_json(allocator: std.mem.Allocator, json_string: []const u8) []const u8 {
    const json_length = json_string.len;
    const max_pretty_length = json_length * 2;
    var pretty_json = allocator.alloc(u8, max_pretty_length) catch return "err";
    defer allocator.free(pretty_json);

    var indent: usize = 0;
    var in_string: bool = false;
    var ptr: usize = 0;
    const tab = 4;

    for (json_string) |c| {
        switch (c) {
            '\"' => {
                in_string = !in_string;
                pretty_json[ptr] = c;
                ptr += 1;
            },
            '{', '[' => {
                pretty_json[ptr] = c;
                ptr += 1;
                if (!in_string) {
                    pretty_json[ptr] = '\n';
                    ptr += 1;
                    indent += 1;
                    for (indent) |_| {
                        for (tab) |_| {
                            pretty_json[ptr] = ' ';
                            ptr += 1;
                        }
                    }
                }
            },
            '}', ']' => {
                if (!in_string) {
                    pretty_json[ptr] = '\n';
                    ptr += 1;
                    indent -= 1;
                    for (indent) |_| {
                        for (tab) |_| {
                            pretty_json[ptr] = ' ';
                            ptr += 1;
                        }
                    }
                }
                pretty_json[ptr] = c;
                ptr += 1;
            },
            ',' => {
                pretty_json[ptr] = c;
                ptr += 1;
                if (!in_string) {
                    pretty_json[ptr] = '\n';
                    ptr += 1;
                    for (indent) |_| {
                        for (tab) |_| {
                            pretty_json[ptr] = ' ';
                            ptr += 1;
                        }
                    }
                }
            },
            ' ' => {
                if (in_string) {
                    pretty_json[ptr] = c;
                    ptr += 1;
                }
            },
            ':' => {
                pretty_json[ptr] = c;
                ptr += 1;
                if (!in_string) {
                    pretty_json[ptr] = ' ';
                    ptr += 1;
                }
            },
            else => {
                pretty_json[ptr] = c;
                ptr += 1;
            },
        }
    }
    pretty_json[ptr] = '0';

    return std.mem.Allocator.dupe(allocator, u8, pretty_json[0..ptr]) catch "err";
}

test "json" {
    const json_string = "{\"name\":\"John\",\"age\":30,\"city\":\"New York\",\"hobbies\":[\"reading\",\"traveling\"]}";
    const v = prettify_json(std.heap.page_allocator, json_string);
    const resp =
        \\{
        \\    "name": "John",
        \\    "age": 30,
        \\    "city": "New York",
        \\    "hobbies": [
        \\        "reading",
        \\        "traveling"
        \\    ]
        \\}
    ;

    try std.testing.expectEqualStrings(v, resp);
}
