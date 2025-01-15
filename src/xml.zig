const std = @import("std");
const util = @import("util.zig");
const testing = std.testing;

pub const isFormatted = util.isFormatted;

pub fn prettify(allocator: std.mem.Allocator, xml: []const u8, pretty_options: util.PrettyOptions) ![]const u8 {
    const max_pretty_length = xml.len * pretty_options.multiply_max_length_by;
    var tags = try allocator.alloc(u8, max_pretty_length);
    defer allocator.free(tags);

    var in_tag: bool = false;
    var index: usize = 0;
    var last: usize = 0;
    var spaces: usize = 0;

    var pretty_xml = std.ArrayList([]const u8).init(allocator);
    defer pretty_xml.deinit();

    for (xml) |c| {
        switch (c) {
            '<' => {
                if (in_tag) {
                    tags[index] = c;
                    index += 1;
                } else {
                    if (index > 0 and tags[index - 1] == '>') {
                        const current = tags[last..index];
                        if (pretty_xml.getLastOrNull()) |v| {
                            addSpaces(&spaces, pretty_options.tab_space, v, current);
                            const item_with_tab = try getItemWithTab(allocator, spaces, current);
                            try pretty_xml.append(item_with_tab);
                        } else {
                            try pretty_xml.append(current);
                        }
                        index += 1;
                        last = index;
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
    try pretty_xml.append(tags[last..index]);

    return try std.mem.join(allocator, "\n", try pretty_xml.toOwnedSlice());
}

fn getItemWithTab(allocator: std.mem.Allocator, spaces: usize, item: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, spaces + item.len);

    for (0..spaces) |i| result[i] = ' ';

    for (item, spaces..) |value, i| result[i] = value;

    return result;
}

fn addSpaces(spaces: *usize, tab: usize, last: []const u8, actual: []const u8) void {
    if (std.mem.startsWith(u8, last, "<?xml")) return;

    if ((std.mem.containsAtLeast(u8, last, 1, "</") or std.mem.endsWith(u8, last, "/>")) and std.mem.startsWith(u8, actual, "</") and spaces.* > 1) {
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
