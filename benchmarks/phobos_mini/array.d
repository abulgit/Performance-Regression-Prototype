/**
 * Mini Phobos-like array module
 */
module phobos_mini.array;

import std.traits;

/**
 * Join an array of elements into a single string.
 */
string join(T)(T[] array, string delimiter = "") {
    if (array.length == 0) return "";

    import std.conv : to;

    string result = to!string(array[0]);
    foreach (element; array[1..$]) {
        result ~= delimiter ~ to!string(element);
    }

    return result;
}

/**
 * Creates a new array by repeating the contents of array a specified number of times.
 */
T[] replicate(T)(T[] array, size_t n) {
    if (n == 0 || array.length == 0) return [];

    T[] result;
    result.length = array.length * n;

    size_t index = 0;
    for (size_t i = 0; i < n; i++) {
        foreach (element; array) {
            result[index++] = element;
        }
    }

    return result;
}

/**
 * Returns the elements of a specified range partitioned
 * into two ranges according to a predicate.
 */
auto partition(alias pred, R)(R range)
    if (isForwardRange!R)
{
    import std.algorithm.mutation : swap;

    auto result = range.save;
    if (range.empty) return result;

    while (!range.empty) {
        if (!pred(range.front)) {
            swap(result.front, range.front);
            result.popFront();
        }
        range.popFront();
    }

    return result;
}

/**
 * Returns a new array containing elements in the specified array which
 * satisfy the specified predicate.
 */
T[] filter(alias pred, T)(T[] array) {
    T[] result;
    foreach (element; array) {
        if (pred(element)) {
            result ~= element;
        }
    }
    return result;
}

/**
 * Creates a new array by applying a function to each element in the specified array.
 */
auto map(alias func, T)(T[] array) {
    alias ReturnType = typeof(func(T.init));
    ReturnType[] result;
    result.length = array.length;

    for (size_t i = 0; i < array.length; i++) {
        result[i] = func(array[i]);
    }

    return result;
}

/**
 * Creates a new array by applying a binary function to successive elements in the array.
 */
T reduce(alias func, T)(T[] array, T seed) {
    T result = seed;
    foreach (element; array) {
        result = func(result, element);
    }
    return result;
}

/**
 * Returns a new array where adjacent elements that compare equal
 * are merged into a single element.
 */
T[] uniq(T)(T[] array) {
    if (array.length <= 1) return array.dup;

    T[] result;
    result ~= array[0];

    for (size_t i = 1; i < array.length; i++) {
        if (array[i] != array[i-1]) {
            result ~= array[i];
        }
    }

    return result;
}

unittest {
    assert(join(["a", "b", "c"], ", ") == "a, b, c");
    assert(replicate([1, 2], 3) == [1, 2, 1, 2, 1, 2]);
    assert(filter!(a => a > 3)([1, 5, 3, 7, 2, 9]) == [5, 7, 9]);
    assert(map!(a => a * 2)([1, 2, 3]) == [2, 4, 6]);
    assert(reduce!((a, b) => a + b)([1, 2, 3, 4], 0) == 10);
    assert(uniq([1, 1, 2, 2, 2, 3, 1, 1, 4]) == [1, 2, 3, 1, 4]);
}