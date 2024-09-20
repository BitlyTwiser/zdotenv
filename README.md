<div align="center"> 

<img src="/assets/zdotenv.png" width="450" height="500">
</div>

Zdotenv is a simple .env parser and a port of godotenv and ruby dotenv, but with a smidge more simplicity.

### Usage:
Add zdotenv to your zig project:
```
zig fetch --save https://github.com/BitlyTwiser/zdotenv/archive/refs/tags/0.1.0.tar.gz
```

Zdotenv has 2 pathways:

1. Absolute path to .env
- Expects an absolute path to the .env (unix systems expect a preceding / in the path)
```
const z = try Zdotenv.init(std.heap.page_allocator);
// Must be an absolute path!
try z.loadFromFile("/home/<username>/Documents/gitclones/zdotenv/test-env.env");
```

2. relaltive path:
- Expects the .env to be placed alongside the calling binary
```
const z = try Zdotenv.init(std.heap.page_allocator);
try z.load();
```

## C usage:
Zig (at the time of this writing) does not have a solid way of directly adjusting the env variables. Doing things like:
```
        var env_map = std.process.getEnvMap(std.heap.page_allocator);
        env_map.put("t", "val");
```

will only adjust the env map for the scope of this execution (i.e. scope of the current calling function). After function exit, the map goes back to its previous state.

Using the package is as simple as the above code examples. import below using zig zon, load the .env, and access the variables as needed using std.process.EnvMap :)
