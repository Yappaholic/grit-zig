const std = @import("std");

pub const QueueError = error{
    EmptyQueue,
};

pub fn Queue(comptime T: type) type{
	return struct {
        stack: [20]?T,
        head: ?T,
        current: ?T,
        count: ?usize,

 		const Self = @This();

        pub fn init() Self {
            return .{
                .stack = undefined,
                .head = null,
                .current = null,
                .count = 0,
            };
        }

        pub fn push(self: *Self, item: T) void {
            const index = self.count.?;
            self.stack[index] = item;
            self.current = self.stack[index];
            self.count.? += 1;
            if (self.count.? == 1) {
                self.head = self.current.?;
            }
        }

        pub fn pop(self: *Self) !void {
            if (self.count.? == 0 ) {
                return error.EmptyQueue;
            }
            self.count.? -= 1;
            const index = self.count.?;
            self.stack[index] = null;
            if (self.count.? == 0) {
                self.head = null;
                self.current = null;
            } else {
                self.current = self.stack[index];
            }
        }

        pub fn empty(self: Self) bool {
            if (self.stack[0] == null) {
                return true;
            } else return false;
        }

        pub fn opened(self: Self) bool {
            if (self.stack[0] == null or self.stack[0] != null) {
                return true;
            } else return false;
        }

        pub fn concat_result(self: Self) !T {
            const allocator = std.heap.page_allocator;
            var array = std.ArrayList(u8).init(allocator);
            for (self.stack) |item| {
                if (item != null) {
                    try array.appendSlice(item.?);
                    try array.appendSlice("\n");
                }
            }
            const result = array.toOwnedSlice();
            return result;
        }
	};
}

