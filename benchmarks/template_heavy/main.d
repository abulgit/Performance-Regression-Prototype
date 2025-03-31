/**
 * Template-heavy benchmark
 *
 * This benchmark tests the DMD compiler's performance with
 * heavy template instantiation.
 */
module main;

// A template with multiple parameters and nesting
template Tuple(T...) {
    alias Tuple = T;
}

// Meta-programming with nested templates
template staticMap(alias F, T...) {
    static if (T.length == 0)
        alias staticMap = Tuple!();
    else
        alias staticMap = Tuple!(F!(T[0]), staticMap!(F, T[1..$]));
}

// Identity template for simple mapping
template Identity(T) {
    alias Identity = T;
}

// A template for type qualifiers
template AddQualifiers(T) {
    alias AddQualifiers = Tuple!(
        T,
        const(T),
        immutable(T),
        shared(T),
        const(shared(T))
    );
}

// Type list with primitives and compounds
alias PrimitiveTypes = Tuple!(
    bool,
    byte, ubyte,
    short, ushort,
    int, uint,
    long, ulong,
    float, double, real,
    char, wchar, dchar
);

// Generate a large type list by adding qualifiers to all primitive types
alias AllTypes = staticMap!(AddQualifiers, PrimitiveTypes);

// A complex template with value parameters and specializations
template Factorial(int n) {
    static if (n <= 1)
        enum Factorial = 1;
    else
        enum Factorial = n * Factorial!(n-1);
}

// Compute some factorials at compile time
enum fact5 = Factorial!5;
enum fact10 = Factorial!10;
enum fact15 = Factorial!15;

// Complex template with specialization
template Container(T) {
    T value;

    void setValue(T val) {
        value = val;
    }

    T getValue() {
        return value;
    }
}

// Specialization for int
template Container(T: int) {
    int value;

    void setValue(int val) {
        value = val * 2; // Different behavior
    }

    int getValue() {
        return value / 2;
    }
}

// Recursive template for compile-time list operations
template LinkedList(T, size_t Len) {
    static if (Len == 0) {
        // Base case: empty list
        struct LinkedList {
            alias Type = T;
            enum length = 0;
        }
    } else {
        // Recursive case
        struct LinkedList {
            T head;
            LinkedList!(T, Len-1) tail;

            alias Type = T;
            enum length = Len;
        }
    }
}

// Instantiate some large linked lists
alias List100 = LinkedList!(int, 100);
alias List200 = LinkedList!(double, 200);

// Template mixin for generating code
mixin template GenerateProperties(T, string[] names) {
    static foreach (name; names) {
        mixin("private T _" ~ name ~ ";");
        mixin("T get" ~ name ~ "() { return _" ~ name ~ "; }");
        mixin("void set" ~ name ~ "(T value) { _" ~ name ~ " = value; }");
    }
}

class TestClass {
    // Generate 50 properties
    mixin GenerateProperties!(int, [
        "prop1", "prop2", "prop3", "prop4", "prop5",
        "prop6", "prop7", "prop8", "prop9", "prop10",
        "prop11", "prop12", "prop13", "prop14", "prop15",
        "prop16", "prop17", "prop18", "prop19", "prop20",
        "prop21", "prop22", "prop23", "prop24", "prop25",
        "prop26", "prop27", "prop28", "prop29", "prop30",
        "prop31", "prop32", "prop33", "prop34", "prop35",
        "prop36", "prop37", "prop38", "prop39", "prop40",
        "prop41", "prop42", "prop43", "prop44", "prop45",
        "prop46", "prop47", "prop48", "prop49", "prop50"
    ]);
}

// Variadic template function
T sum(T)(T first) {
    return first;
}

T sum(T, Args...)(T first, Args rest) {
    static if (rest.length == 0)
        return first;
    else
        return first + sum(rest);
}

// Main function (not used during compilation benchmark)
void main() {
    import std.stdio;

    writeln("Template-heavy benchmark for DMD");

    // Just to ensure some code is used
    auto test = new TestClass();
    test.setprop1(42);
    writeln("prop1 = ", test.getprop1());

    writeln("Factorial of 10: ", fact10);

    // Use the sum function
    writeln("Sum: ", sum(1, 2, 3, 4, 5));
}