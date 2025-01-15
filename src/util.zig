const std = @import("std");

/// Checks if the given string is formatted (i.e., contains at least one newline character).
///
/// @param string The input string to check.
/// @return `true` if the string contains at least one newline character, `false` otherwise.
pub fn isFormatted(string: []const u8) bool {
    return std.mem.containsAtLeast(u8, string, 1, "\n");
}

/// Defines the options for pretty-printing.
pub const PrettyOptions = struct {
    /// The number of spaces to use for each tab.
    tab_space: u8 = 2,

    /// The factor to multiply the maximum length of a line when determining the maximum length for pretty-printing.
    /// If some `panic: index out of bounds` is returned, try to increase this value.
    multiply_max_length: u8 = 4,
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
