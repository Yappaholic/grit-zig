const std = @import("std");

pub const QueueError = error{
    EmptyQueue,
};

pub const QueueSet = struct {
    queue: Queue,
    stack: ?[10]?[]const u8,
};

pub const Queue = struct {
    stack: ?[10]?[]const u8,
    head: ?[]const u8,
    current: ?[]const u8,
    count: ?usize,

    // Initialize the queue with stack array
    pub fn init(self: *Queue, stack: ?[10]?[]const u8) void{
        self.stack = stack;
        self.count = 0;
    }

    pub fn push(self: *Queue, item: []const u8) void {
        const index = self.count.?;
        self.stack.?[index] = item;
        self.current = self.stack.?[index];
        self.count.? += 1;
        if (self.count.? == 1) {
            self.head = self.current.?;
        }
    }

    pub fn pop(self: *Queue) !void {
        if (self.count.? == 0 ) {
            return error.EmptyQueue;
        }
        self.count.? -= 1;
        const index = self.count.?;
        self.stack.?[index] = null;
        if (self.count.? == 0) {
            self.head = null;
            self.current = null;
        } else {
            self.current = self.stack.?[index];
        }
    }
};

pub fn create_queue(stack: [10]?[]const u8) Queue{
    var q = Queue{.stack = null, .head = null, .current = null, .count = null};
    q.init(stack);
    return q;
}
