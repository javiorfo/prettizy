const std = @import("std");

pub fn isFormatted() void {}

fn getItemWithTab(allocator: std.mem.Allocator, spaces: usize, item: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, spaces + item.len);

    for (0..spaces) |i| result[i] = ' ';

    for (item, spaces..) |value, i| result[i] = value;

    return result;
}

fn addSpaces(spaces: *usize, last: []const u8, actual: []const u8) void {
    if (std.mem.startsWith(u8, last, "<?xml")) return;

    if ((std.mem.containsAtLeast(u8, last, 1, "</") or std.mem.endsWith(u8, last, "/>")) and std.mem.startsWith(u8, actual, "</") and spaces.* > 1) {
        spaces.* -= 2;
    } else if (!std.mem.containsAtLeast(u8, last, 1, "</") and !std.mem.endsWith(u8, last, "/>")) {
        spaces.* += 2;
    }
}

pub const XMLOptions = struct {
    tab_space: u8 = 2,
    multiply_max_length_by: u8 = 4,
};

fn prettify_xml2(allocator: std.mem.Allocator, xml: []const u8) ![]const u8 {
    const max_pretty_length = xml.len * 4;
    var result = try allocator.alloc(u8, max_pretty_length);
    defer allocator.free(result);

    var in_tag: bool = false;
    var index: usize = 0;
    var last: usize = 0;
    var spaces: usize = 0;

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    for (xml) |c| {
        switch (c) {
            '<' => {
                if (in_tag) {
                    result[index] = c;
                    index += 1;
                } else {
                    if (index > 0 and result[index - 1] == '>') {
                        const current = result[last..index];
                        if (list.getLastOrNull()) |v| {
                            addSpaces(&spaces, v, current);
                            const item_with_tab = try getItemWithTab(allocator, spaces, current);
                            try list.append(item_with_tab);
                        } else {
                            try list.append(current);
                        }
                        index += 1;
                        last = index;
                    }
                    in_tag = true;
                    result[index] = c;
                    index += 1;
                }
            },
            '>' => {
                in_tag = false;
                result[index] = c;
                index += 1;
            },
            else => {
                result[index] = c;
                index += 1;
            },
        }
    }
    result[index] = '0';
    try list.append(result[last..index]);

    return try std.mem.join(allocator, "\n", try list.toOwnedSlice());
}

fn prettify_xml(allocator: std.mem.Allocator, xml: []const u8) ![]const u8 {
    const xml_length = xml.len;
    const max_pretty_length = xml_length * 2;
    var result = allocator.alloc(u8, max_pretty_length) catch return "err";
    defer allocator.free(result);

    var in_tag: bool = false;
    var ptr: usize = 0;

    for (xml) |c| {
        switch (c) {
            '<' => {
                if (in_tag) {
                    result[ptr] = c;
                    ptr += 1;
                } else {
                    if (ptr > 0 and result[ptr - 1] == '>') {
                        result[ptr] = '\n';
                        ptr += 1;
                    }
                    in_tag = true;
                    result[ptr] = c;
                    ptr += 1;
                }
            },
            '>' => {
                in_tag = false;
                result[ptr] = c;
                ptr += 1;
            },
            else => {
                result[ptr] = c;
                ptr += 1;
            },
        }
    }
    result[ptr] = '0';

    return std.mem.Allocator.dupe(allocator, u8, result[0..ptr]) catch "err";
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    //     const xml_input = "<root><child>hola</child><apa><tag id=1/></apa><inner><papa value='fas' /></inner></root>";
    const xml_input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><library><name>City Library</name><location><address><street>Main St</street><number>123</number><city>Metropolis</city><state>NY</state><zip>12345</zip></address><coordinates><latitude>40.7128</latitude><longitude>-74.0060</longitude></coordinates></location><books><book id=\"b1\"><title>The Great Gatsby</title><author><firstName>F. Scott</firstName><lastName>Fitzgerald</lastName></author><publicationYear>1925</publicationYear><genre>Fiction</genre><isbn>9780743273565</isbn><availability><status>available</status><copies>5</copies></availability></book><book id=\"b2\"><title>1984</title><author><firstName>George</firstName><lastName>Orwell</lastName></author><publicationYear>1949</publicationYear><genre>Dystopian</genre><isbn>9780451524935</isbn><availability><status>checked out</status><dueDate>2023-10-15</dueDate><copies>0</copies></availability></book><book id=\"b3\"><title>To Kill a Mockingbird</title><author><firstName>Harper</firstName><lastName>Lee</lastName></author><publicationYear>1960</publicationYear><genre>Fiction</genre><isbn>9780061120084</isbn><availability><status>available</status><copies>3</copies></availability></book></books><members><member id=\"m1\"><name><firstName>John</firstName><lastName>Doe</lastName></name><membershipDate>2020-01-15</membershipDate><email>john.doe@example.com</email><borrowedBooks><bookRef id=\"b2\" /></borrowedBooks></member><member id=\"m2\"><name><firstName>Jane</firstName><lastName>Smith</lastName></name><membershipDate>2021-06-20</membershipDate><email>jane.smith@example.com</email><borrowedBooks><bookRef id=\"b1\" /><bookRef id=\"b3\" /></borrowedBooks></member></members><staff><staffMember id=\"s1\"><name><firstName>Alice</firstName><lastName>Johnson</lastName></name><position>Librarian</position><email>alice.johnson@citylibrary.com</email></staffMember><staffMember id=\"s2\"><name><firstName>Bob</firstName><lastName>Williams</lastName></name><position>Assistant Librarian</position><email>bob.williams@citylibrary.com</email></staffMember></staff></library>";

    //     const indices = try findNewlineIndices(formatted_xml);
    //
    //     for (indices) |index| {
    //         std.debug.print("Newline found at index: {}\n", .{index});
    //     }
    const array = try prettify_xml2(allocator, xml_input);
    std.debug.print("{s}\n", .{array});
}

test "xml" {
    const xml_input = "<root><child></child></root>";
    const formatted_xml = try prettify_xml(std.testing.allocator, xml_input);
    defer std.testing.allocator.free(formatted_xml);

    const formatted = try prettify_xml2(std.testing.allocator, xml_input);
    defer std.testing.allocator.free(formatted);
}
