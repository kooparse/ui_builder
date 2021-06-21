const std = @import("std");

const p_alloc = std.heap.page_allocator;
const mem = std.mem;
const Allocator = mem.Allocator;
const print = std.debug.print;
const StringHashMap = std.StringHashMap;
const AutoHashMap = std.AutoHashMap;

pub fn StringBufSet(comptime T: anytype) type {
    return struct {
        hash_map: StringHashMap(T),

        const Self = @This();

        pub fn init(allocator: *mem.Allocator) Self {
            return .{ .hash_map = StringHashMap(T).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            var it = self.hash_map.iterator();
            while (it.next()) |entry| self.free(entry.key_ptr.*);

            self.hash_map.deinit();
        }

        /// `key` is copied into the BufMap.
        pub fn put(self: *Self, key: []const u8, value: T) !void {
            var get_or_put = try self.hash_map.getOrPut(key);

            if (!get_or_put.found_existing) {
                get_or_put.key_ptr.* = self.copy(key) catch |err| {
                    _ = self.hash_map.remove(key);
                    return err;
                };
            }

            get_or_put.value_ptr.* = value;
        }

        pub fn get(self: Self, key: []const u8) ?T {
            return self.hash_map.get(key);
        }

        pub fn contains(self: Self, key: []const u8) bool {
            return self.hash_map.contains(key);
        }

        pub fn getEntry(self: Self, key: []const u8) ?StringHashMap(T).Entry {
            return self.hash_map.getEntry(key);
        }

        pub fn delete(self: *Self, key: []const u8) void {
            const entry = self.hash_map.remove(key) orelse return;
            self.free(entry.key);
        }

        pub fn count(self: Self) usize {
            return self.hash_map.count();
        }

        pub fn iterator(self: *const Self) StringHashMap(T).Iterator {
            return self.hash_map.iterator();
        }

        fn free(self: Self, value: []const u8) void {
            self.hash_map.allocator.free(value);
        }

        fn copy(self: Self, value: []const u8) ![]u8 {
            return self.hash_map.allocator.dupe(u8, value);
        }
    };
}
