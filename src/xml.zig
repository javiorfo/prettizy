const std = @import("std");
const util = @import("util.zig");
const testing = std.testing;

pub const isFormatted = util.isFormatted;

/// Prettifies the given XML string using the provided options.
///
/// @param allocator The memory allocator to use for the resulting string (ArenaAllocator recommended).
/// @param xml_string The input XML string to prettify.
/// @param pretty_options The options to use for pretty-printing.
/// @return The prettified XML string, or an error if the operation fails.
pub fn prettify(allocator: std.mem.Allocator, xml_string: []const u8, pretty_options: util.PrettyOptions) ![]const u8 {
    const max_pretty_length = xml_string.len * pretty_options.multiply_max_length;
    var tags = try allocator.alloc(u8, max_pretty_length);
    defer allocator.free(tags);

    var in_tag: bool = false;
    var index: usize = 0;
    var last_index: usize = 0;
    var spaces: usize = 0;

    var pretty_xml = std.ArrayList([]const u8).init(allocator);
    defer pretty_xml.deinit();

    for (xml_string) |c| {
        switch (c) {
            '<' => {
                if (in_tag) {
                    tags[index] = c;
                    index += 1;
                } else {
                    if (index > 0 and tags[index - 1] == '>') {
                        const current = tags[last_index..index];
                        if (pretty_xml.getLastOrNull()) |last| {
                            addSpaces(&spaces, pretty_options.tab_space, last, current);
                            const item_with_tab = try getItemWithTab(allocator, spaces, current);
                            try pretty_xml.append(item_with_tab);
                        } else {
                            try pretty_xml.append(current);
                        }
                        index += 1;
                        last_index = index;
                    }
                    in_tag = true;
                    tags[index] = c;
                    index += 1;
                }
            },
            '>' => {
                in_tag = false;
                tags[index] = c;
                index += 1;
            },
            else => {
                tags[index] = c;
                index += 1;
            },
        }
    }
    tags[index] = '0';
    try pretty_xml.append(tags[last_index..index]);

    return try std.mem.join(allocator, "\n", try pretty_xml.toOwnedSlice());
}

/// Allocates a new string with the specified number of leading spaces, followed by the given item.
///
/// @param allocator The memory allocator to use for the resulting string.
/// @param spaces The number of leading spaces to add.
/// @param item The item to append to the string.
/// @return The new string with the leading spaces and the item, or an error if the allocation fails.
fn getItemWithTab(allocator: std.mem.Allocator, spaces: usize, item: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, spaces + item.len);

    for (0..spaces) |i| result[i] = ' ';

    for (item, spaces..) |value, i| result[i] = value;

    return result;
}

/// Adjusts the number of spaces based on the current and previous XML elements.
///
/// @param spaces A pointer to the current number of spaces, which will be updated.
/// @param tab The number of spaces to use for each indentation level.
/// @param last The previous XML element.
/// @param current The current XML element.
fn addSpaces(spaces: *usize, tab: usize, last: []const u8, current: []const u8) void {
    if (std.mem.startsWith(u8, last, "<?xml")) return;

    if ((std.mem.containsAtLeast(u8, last, 1, "</") or std.mem.endsWith(u8, last, "/>")) and std.mem.startsWith(u8, current, "</") and spaces.* > 1) {
        spaces.* -= tab;
    } else if (!std.mem.containsAtLeast(u8, last, 1, "</") and !std.mem.endsWith(u8, last, "/>")) {
        spaces.* += tab;
    }
}

test "xml" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const xml_input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><library><name>City Library</name><location><address><street>Main St</street><number>123</number><city>Metropolis</city><state>NY</state><zip>12345</zip></address><coordinates><latitude>40.7128</latitude><longitude>-74.0060</longitude></coordinates></location><books><book id=\"b1\"><title>The Great Gatsby</title><author><firstName>F. Scott</firstName><lastName>Fitzgerald</lastName></author><publicationYear>1925</publicationYear><genre>Fiction</genre><isbn>9780743273565</isbn><availability><status>available</status><copies>5</copies></availability></book></books></library>";
    const formatted_xml = try prettify(allocator, xml_input, .{});

    const expected =
        \\<?xml version="1.0" encoding="UTF-8"?>
        \\<library>
        \\  <name>City Library</name>
        \\  <location>
        \\    <address>
        \\      <street>Main St</street>
        \\      <number>123</number>
        \\      <city>Metropolis</city>
        \\      <state>NY</state>
        \\      <zip>12345</zip>
        \\    </address>
        \\    <coordinates>
        \\      <latitude>40.7128</latitude>
        \\      <longitude>-74.0060</longitude>
        \\    </coordinates>
        \\  </location>
        \\  <books>
        \\    <book id="b1">
        \\      <title>The Great Gatsby</title>
        \\      <author>
        \\        <firstName>F. Scott</firstName>
        \\        <lastName>Fitzgerald</lastName>
        \\      </author>
        \\      <publicationYear>1925</publicationYear>
        \\      <genre>Fiction</genre>
        \\      <isbn>9780743273565</isbn>
        \\      <availability>
        \\        <status>available</status>
        \\        <copies>5</copies>
        \\      </availability>
        \\    </book>
        \\  </books>
        \\</library>
    ;

    try testing.expectEqualStrings(formatted_xml, expected);
}
