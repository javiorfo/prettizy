# prettizy
*Zig library to prettify JSON and XML files*

## Caveats
- Required Zig version: **0.13**
- This library has been developed on and for Linux following open source philosophy.

## Usage
```zig
```

## Installation
#### In `build.zig.zon`:
```zig
.dependencies = .{
    .syslinfo = .{
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
