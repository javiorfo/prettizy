# prettizy
*Zig library to prettify JSON and XML strings*

## Caveats
- Required Zig version: **0.14.1**
- This library has been developed on and for Linux following open source philosophy.

## Usage
```zig
const std = @import("std");
const prettizy = @import("prettizy");

pub fn main() !void {
    // Arena Allocator is recommended to avoid internal leaks
    var gpa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer gpa.deinit();
    const allocator = gpa.allocator();

    const json_string = "{\"name\":\"John\",\"age\":30,\"city\":\"New York\",\"hobbies\":[\"reading\",\"traveling\"], \"obj\":{\"field\":[1,2]}}";
    const formatted_json = try prettizy.json.prettify(allocator, json_string, .{});
    std.debug.print("{s}\n", .{formatted_json});

    const xml_input = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><library><name>City Library</name><location><address><street>Main St</street><number>123</number><city>Metropolis</city><state>NY</state><zip>12345</zip></address><coordinates><latitude>40.7128</latitude><longitude>-74.0060</longitude></coordinates></location><books><book id=\"b1\"><title>The Great Gatsby</title><author><firstName>F. Scott</firstName><lastName>Fitzgerald</lastName></author><publicationYear>1925</publicationYear><genre>Fiction</genre><isbn>9780743273565</isbn><availability><status>available</status><copies>5</copies></availability></book></books></library>";
    const formatted_xml = try prettizy.xml.prettify(allocator, xml_input, .{ .tab_space = 4 });
    std.debug.print("{s}\n", .{formatted_xml});
}
```

## Installation
#### In `build.zig.zon`:
```zig
.dependencies = .{
    .prettizy = .{
        .url = "https://github.com/javiorfo/prettizy/archive/refs/heads/master.tar.gz",            
        // .hash = "hash suggested",
        // the hash will be suggested by zig build
    },
}
```

#### In `build.zig`:
```zig
const dep = b.dependency("prettizy", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("prettizy", dep.module("prettizy"));
```

---

### Donate
- **Bitcoin** [(QR)](https://raw.githubusercontent.com/javiorfo/img/master/crypto/bitcoin.png)  `1GqdJ63RDPE4eJKujHi166FAyigvHu5R7v`
- [Paypal](https://www.paypal.com/donate/?hosted_button_id=FA7SGLSCT2H8G)
