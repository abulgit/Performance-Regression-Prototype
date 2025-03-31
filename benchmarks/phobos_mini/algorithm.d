/**
 * Mini Phobos-like algorithm module
 */
module phobos_mini.algorithm;

import std.traits;
import std.range;

/**
 * Find the minimum element in a range.
 */
auto min(T)(T[] range) {
    if (range.empty) {
        throw new Exception("Cannot get minimum of an empty range");
    }

    auto result = range[0];
    foreach (element; range[1..$]) {
        if (element < result) {
            result = element;
        }
    }

    return result;
}

/**
 * Find the maximum element in a range.
 */
auto max(T)(T[] range) {
    if (range.empty) {
        throw new Exception("Cannot get maximum of an empty range");
    }

    auto result = range[0];
    foreach (element; range[1..$]) {
        if (element > result) {
            result = element;
        }
    }

    return result;
}

/**
 * Sort an array in-place using a simple insertion sort algorithm.
 */
void sort(T)(T[] array) {
    for (size_t i = 1; i < array.length; i++) {
        auto key = array[i];
        long j = i - 1;

        while (j >= 0 && array[j] > key) {
            array[j + 1] = array[j];
            j--;
        }

        array[j + 1] = key;
    }
}

/**
 * Find the first element in a range that satisfies a predicate.
 */
auto find(alias pred, R)(R range) if (isInputRange!R) {
    while (!range.empty) {
        if (pred(range.front)) {
            return range;
        }
        range.popFront();
    }
    return range;
}

/**
 * Count elements in a range that satisfy a predicate.
 */
size_t count(alias pred, R)(R range) if (isInputRange!R) {
    size_t counter = 0;
    while (!range.empty) {
        if (pred(range.front)) {
            counter++;
        }
        range.popFront();
    }
    return counter;
}

/**
 * Check if any element in the range satisfies the predicate.
 */
bool any(alias pred, R)(R range) if (isInputRange!R) {
    while (!range.empty) {
        if (pred(range.front)) {
            return true;
        }
        range.popFront();
    }
    return false;
}

/**
 * Check if all elements in the range satisfy the predicate.
 */
bool all(alias pred, R)(R range) if (isInputRange!R) {
    while (!range.empty) {
        if (!pred(range.front)) {
            return false;
        }
        range.popFront();
    }
    return true;
}

/**
 * Return a range that skips the first n elements.
 */
auto drop(R)(R range, size_t n) if (isInputRange!R) {
    auto result = range.save;
    size_t i = 0;
    while (!result.empty && i < n) {
        result.popFront();
        i++;
    }
    return result;
}

/**
 * Return a range that takes only the first n elements.
 */
auto take(R)(R range, size_t n) if (isInputRange!R) {
    static struct TakeResult {
        private R source;
        private size_t remaining;

        this(R source, size_t n) {
            this.source = source;
            this.remaining = n;
        }

        @property bool empty() {
            return remaining == 0 || source.empty;
        }

        @property auto front() {
            return source.front;
        }

        void popFront() {
            if (!empty) {
                source.popFront();
                remaining--;
            }
        }

        @property auto save() {
            return TakeResult(source.save, remaining);
        }
    }

    return TakeResult(range, n);
}

unittest {
    assert(min([3, 1, 4, 1, 5]) == 1);
    assert(max([3, 1, 4, 1, 5]) == 5);

    int[] arr = [5, 2, 4, 1, 3];
    sort(arr);
    assert(arr == [1, 2, 3, 4, 5]);

    auto range = [1, 3, 5, 7, 9];
    auto result = find!(a => a > 4)(range);
    assert(result.front == 5);

    assert(count!(a => a % 2 == 0)([1, 2, 3, 4, 5]) == 2);
    assert(any!(a => a > 3)([1, 2, 3, 4, 5]));
    assert(!all!(a => a > 3)([1, 2, 3, 4, 5]));

    auto numbers = [1, 2, 3, 4, 5];
    assert(drop(numbers, 2).front == 3);
    assert(take(numbers, 3).array == [1, 2, 3]);
}