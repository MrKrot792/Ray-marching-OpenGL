const std = @import("std");
const gl = @import("zgl");
const glfw = @import("zglfw");

pub const Game = struct {
    // Some game things

    pub fn run(alloc: std.mem.Allocator) !void {
        var arena = std.heap.ArenaAllocator.init(alloc);
        defer arena.deinit();

        const allocator = arena.allocator();

        try glfw.init();
        defer glfw.terminate();

        glfw.windowHint(.context_version_major, 3);
        glfw.windowHint(.context_version_minor, 3);
        glfw.windowHint(.opengl_profile, .opengl_core_profile);
        glfw.windowHint(.resizable, false);

        const window = try glfw.Window.create(600, 600, "zig-gamedev: minimal_glfw_gl", null);
        defer window.destroy();
        glfw.makeContextCurrent(window);

        try gl.loadExtensions(void, getProcAddressWrapper);

        const vertices = [_]f32{
            -0.5, -0.5, 0.0,
             0.5, -0.5, 0.0,
             0.0,  0.5, 0.0,
        };

        const vao = gl.createVertexArray();
        vao.bind();
        defer vao.delete();

        const vbo = gl.createBuffer();
        defer gl.deleteBuffer(vbo);
        gl.bindBuffer(vbo, gl.BufferTarget.array_buffer);
        gl.bufferData(gl.BufferTarget.array_buffer, f32, &vertices, gl.BufferUsage.static_draw);

        gl.vertexAttribPointer(0, 3, .float, false, 3 * @sizeOf(f32), 0);
        gl.enableVertexAttribArray(0);
        
        // Setting some shader up
        var sourceVertex = try readFile(allocator, "assets/vertex.vert");

        const vertexShader = gl.createShader(.vertex);
        defer vertexShader.delete();
        gl.shaderSource(vertexShader, 1, &sourceVertex);
        gl.compileShader(vertexShader);

        var fragmentSource = try readFile(allocator, "assets/fragment.frag");

        const fragmentShader = gl.createShader(.fragment);
        defer fragmentShader.delete();
        gl.shaderSource(fragmentShader, 1, &fragmentSource);
        gl.compileShader(fragmentShader);

        const shaderProgram = gl.createProgram();
        defer shaderProgram.delete();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        while (!window.shouldClose()) {
            glfw.pollEvents();
            proccesInput(window);

            gl.clearColor(0.2, 0.3, 0.3, 1.0);
            gl.clear(.{ .color = true });

            // Rendering
            gl.useProgram(shaderProgram); // Using the created shader
            gl.bindVertexArray(vao);
            gl.drawArrays(.triangles, 0, 3);
            
            window.swapBuffers();
        }
    }
};

fn getProcAddressWrapper(comptime _: type, symbolName: [:0]const u8) ?*const anyopaque {
    return glfw.getProcAddress(symbolName);
}

fn proccesInput(window: *glfw.Window) void {
    if(window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}

pub fn readFile(allocator: std.mem.Allocator, file_path: [] const u8) ![]u8 {
    var file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const file_size = try file.getEndPos();

    var reader = file.reader(&.{});
    const file_content = try reader.interface.readAlloc(allocator, file_size);

    return file_content;
}
