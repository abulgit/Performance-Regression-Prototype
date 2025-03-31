/**
 * Main entry point for phobos_mini benchmark
 *
 * This file uses the mini Phobos implementation to test
 * compilation performance.
 */
module main;

import phobos_mini;

void main() {
    import std.stdio;

    writeln("Phobos Mini benchmark for DMD");

    // Test arrays
    int[] arr = [1, 2, 3, 4, 5];
    arr = arr.dup;

    // Test algorithms
    arr.sort();

    // Test containers
    auto queue = Queue!int.create();
    foreach(i; 0..100) {
        queue.push(i);
    }

    while(!queue.empty()) {
        queue.pop();
    }

    writeln("Benchmark completed");
}