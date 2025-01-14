const std = @import("std");

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

fn findNewlineIndices(data: []const u8) ![]usize {
    var indices = std.ArrayList(usize).init(std.heap.page_allocator);
    for (data, 0..) |c, i| {
        if (c == '\n') {
            try indices.append(i);
        }
    }
    return indices.toOwnedSlice();
}

pub fn main() !void {
    const xml_input = "<root><child>hola</child><papa value='fas' /></root>";
    //     const xml_input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><library><name>City Library</name><location><address><street>Main St</street><number>123</number><city>Metropolis</city><state>NY</state><zip>12345</zip></address><coordinates><latitude>40.7128</latitude><longitude>-74.0060</longitude></coordinates></location><books><book id=\"b1\"><title>The Great Gatsby</title><author><firstName>F. Scott</firstName><lastName>Fitzgerald</lastName></author><publicationYear>1925</publicationYear><genre>Fiction</genre><isbn>9780743273565</isbn><availability><status>available</status><copies>5</copies></availability></book><book id=\"b2\"><title>1984</title><author><firstName>George</firstName><lastName>Orwell</lastName></author><publicationYear>1949</publicationYear><genre>Dystopian</genre><isbn>9780451524935</isbn><availability><status>checked out</status><dueDate>2023-10-15</dueDate><copies>0</copies></availability></book><book id=\"b3\"><title>To Kill a Mockingbird</title><author><firstName>Harper</firstName><lastName>Lee</lastName></author><publicationYear>1960</publicationYear><genre>Fiction</genre><isbn>9780061120084</isbn><availability><status>available</status><copies>3</copies></availability></book></books><members><member id=\"m1\"><name><firstName>John</firstName><lastName>Doe</lastName></name><membershipDate>2020-01-15</membershipDate><email>john.doe@example.com</email><borrowedBooks><bookRef id=\"b2\" /></borrowedBooks></member><member id=\"m2\"><name><firstName>Jane</firstName><lastName>Smith</lastName></name><membershipDate>2021-06-20</membershipDate><email>jane.smith@example.com</email><borrowedBooks><bookRef id=\"b1\" /><bookRef id=\"b3\" /></borrowedBooks></member></members><staff><staffMember id=\"s1\"><name><firstName>Alice</firstName><lastName>Johnson</lastName></name><position>Librarian</position><email>alice.johnson@citylibrary.com</email></staffMember><staffMember id=\"s2\"><name><firstName>Bob</firstName><lastName>Williams</lastName></name><position>Assistant Librarian</position><email>bob.williams@citylibrary.com</email></staffMember></staff></library>";
    const formatted_xml = try prettify_xml(std.heap.page_allocator, xml_input);
    std.debug.print("Formatted XML:\n{s}\n\n", .{formatted_xml});
    std.debug.print("one: {s}\n", .{formatted_xml[0..6]});
    std.debug.print("two: {s}\n", .{formatted_xml[27..47]});
    std.debug.print("two: {s}\n", .{formatted_xml[48..formatted_xml.len]});

    const indices = try findNewlineIndices(formatted_xml);

    for (indices) |index| {
        std.debug.print("Newline found at index: {}\n", .{index});
    }
}

test "xml" {
    const xml_input = "<root><child></child></root>";
    const formatted_xml = try prettify_xml(std.testing.allocator, xml_input);
    defer std.testing.allocator.free(formatted_xml);
    std.debug.print("Formatted XML:\n {s}\n", .{formatted_xml});
}
