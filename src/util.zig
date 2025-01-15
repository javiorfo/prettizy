const std = @import("std");

pub fn isFormatted(string: []const u8) bool {
    return std.mem.containsAtLeast(u8, string, 1, "\n");
}

pub const PrettyOptions = struct {
    tab_space: u8 = 2,
    multiply_max_length_by: u8 = 4,
};

test "util" {
    const testing = std.testing;
    const formatted =
        \\{
        \\    "name": "John",
        \\    "age": 30,
        \\    "city": "New York",
        \\    "hobbies": [
        \\        "reading",
        \\        "traveling"
        \\    ],
        \\    "obj": {
        \\        "field": 20
        \\    }
        \\}
    ;

    try testing.expect(isFormatted(formatted));

    const no_formatted = "{\"name\":\"John\",\"age\":30,\"city\":\"New York\",\"hobbies\":[\"reading\",\"traveling\"], \"obj\":{\"field\":20}}";
    try testing.expect(!isFormatted(no_formatted));
}
