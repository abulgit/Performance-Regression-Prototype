/**
 * Mini Phobos-like container module
 */
module phobos_mini.container;

/**
 * A simple dynamic array implementation.
 */
struct DynamicArray(T) {
private:
    T[] data;
    size_t _length;
    size_t capacity;

    void ensureCapacity(size_t newCapacity) {
        if (capacity >= newCapacity) return;

        size_t newSize = capacity ? capacity * 2 : 8;
        while (newSize < newCapacity) {
            newSize *= 2;
        }

        T[] newData = new T[newSize];
        for (size_t i = 0; i < _length; i++) {
            newData[i] = data[i];
        }

        data = newData;
        capacity = newSize;
    }

public:
    this(size_t initialCapacity) {
        if (initialCapacity > 0) {
            data = new T[initialCapacity];
            capacity = initialCapacity;
            _length = 0;
        }
    }

    this(T[] items) {
        ensureCapacity(items.length);
        for (size_t i = 0; i < items.length; i++) {
            data[i] = items[i];
        }
        _length = items.length;
    }

    @property size_t length() const {
        return _length;
    }

    @property bool empty() const {
        return _length == 0;
    }

    void reserve(size_t capacity) {
        ensureCapacity(capacity);
    }

    ref T opIndex(size_t index) {
        if (index >= _length) {
            throw new Exception("Index out of bounds");
        }
        return data[index];
    }

    void opIndexAssign(T value, size_t index) {
        if (index >= _length) {
            throw new Exception("Index out of bounds");
        }
        data[index] = value;
    }

    void insertBack(T item) {
        ensureCapacity(_length + 1);
        data[_length++] = item;
    }

    void removeBack() {
        if (_length > 0) {
            _length--;
        }
    }

    T[] opSlice() {
        return data[0 .. _length].dup;
    }

    T[] opSlice(size_t start, size_t end) {
        if (start > end || end > _length) {
            throw new Exception("Invalid slice range");
        }
        return data[start .. end].dup;
    }
}

/**
 * A simple linked list implementation.
 */
class LinkedList(T) {
private:
    static class Node {
        T data;
        Node next;

        this(T data, Node next = null) {
            this.data = data;
            this.next = next;
        }
    }

    Node head;
    Node tail;
    size_t _length;

public:
    this() {
        head = null;
        tail = null;
        _length = 0;
    }

    @property size_t length() const {
        return _length;
    }

    @property bool empty() const {
        return _length == 0;
    }

    void add(T data) {
        auto newNode = new Node(data);

        if (head is null) {
            head = newNode;
            tail = newNode;
        } else {
            tail.next = newNode;
            tail = newNode;
        }

        _length++;
    }

    void addFront(T data) {
        head = new Node(data, head);

        if (tail is null) {
            tail = head;
        }

        _length++;
    }

    T front() {
        if (empty) {
            throw new Exception("LinkedList is empty");
        }
        return head.data;
    }

    void removeFront() {
        if (empty) {
            throw new Exception("LinkedList is empty");
        }

        head = head.next;
        _length--;

        if (head is null) {
            tail = null;
        }
    }

    T[] toArray() {
        T[] result = new T[_length];
        Node current = head;
        size_t index = 0;

        while (current !is null) {
            result[index++] = current.data;
            current = current.next;
        }

        return result;
    }
}

/**
 * A simple hash map implementation.
 */
struct HashMap(K, V) {
private:
    static struct Pair {
        K key;
        V value;
    }

    static struct Bucket {
        Pair[] pairs;
    }

    Bucket[] buckets;
    size_t _length;

    size_t hashFunction(K key) {
        import std.traits : isIntegral;

        static if (isIntegral!K) {
            return key % buckets.length;
        } else {
            auto hash = typeid(K).getHash(&key);
            return hash % buckets.length;
        }
    }

public:
    this(size_t initialCapacity) {
        buckets = new Bucket[initialCapacity > 0 ? initialCapacity : 16];
        _length = 0;
    }

    @property size_t length() const {
        return _length;
    }

    @property bool empty() const {
        return _length == 0;
    }

    void put(K key, V value) {
        auto hash = hashFunction(key);

        foreach (ref pair; buckets[hash].pairs) {
            if (pair.key == key) {
                pair.value = value;
                return;
            }
        }

        buckets[hash].pairs ~= Pair(key, value);
        _length++;
    }

    bool get(K key, ref V value) {
        auto hash = hashFunction(key);

        foreach (pair; buckets[hash].pairs) {
            if (pair.key == key) {
                value = pair.value;
                return true;
            }
        }

        return false;
    }

    bool remove(K key) {
        auto hash = hashFunction(key);

        for (size_t i = 0; i < buckets[hash].pairs.length; i++) {
            if (buckets[hash].pairs[i].key == key) {
                buckets[hash].pairs = buckets[hash].pairs[0..i] ~ buckets[hash].pairs[i+1..$];
                _length--;
                return true;
            }
        }

        return false;
    }

    bool containsKey(K key) {
        V dummy;
        return get(key, dummy);
    }

    K[] keys() {
        K[] result;

        foreach (bucket; buckets) {
            foreach (pair; bucket.pairs) {
                result ~= pair.key;
            }
        }

        return result;
    }

    V[] values() {
        V[] result;

        foreach (bucket; buckets) {
            foreach (pair; bucket.pairs) {
                result ~= pair.value;
            }
        }

        return result;
    }
}

/**
 * A simple queue implementation.
 */
struct Queue(T) {
private:
    LinkedList!T list;

public:
    // Empty constructor without parameters or body (will be generated automatically)
    @disable this();

    // Constructor with dummy parameter to allow initialization
    this(bool dummy) {
        list = new LinkedList!T();
    }

    // Factory method to create a new Queue
    static Queue!T create() {
        Queue!T queue = Queue!T(true);
        return queue;
    }

    @property size_t length() const {
        return list.length;
    }

    @property bool empty() const {
        return list.empty;
    }

    void push(T item) {
        list.add(item);
    }

    T front() {
        return list.front();
    }

    void pop() {
        list.removeFront();
    }

    T[] toArray() {
        return list.toArray();
    }
}

unittest {
    // Test DynamicArray
    auto arr = DynamicArray!int(5);
    assert(arr.empty);
    assert(arr.length == 0);

    for (int i = 0; i < 10; i++) {
        arr.insertBack(i);
    }

    assert(arr.length == 10);
    assert(arr[5] == 5);

    arr[3] = 42;
    assert(arr[3] == 42);

    arr.removeBack();
    assert(arr.length == 9);

    auto slice = arr[2..5];
    assert(slice.length == 3);
    assert(slice[0] == 2);
    assert(slice[1] == 42);

    // Test LinkedList
    auto list = new LinkedList!string();
    assert(list.empty);

    list.add("first");
    list.add("second");
    list.addFront("zero");

    assert(list.length == 3);
    assert(list.front() == "zero");

    list.removeFront();
    assert(list.front() == "first");

    auto array = list.toArray();
    assert(array.length == 2);
    assert(array[0] == "first");
    assert(array[1] == "second");

    // Test HashMap
    auto map = HashMap!(string, int)(10);
    assert(map.empty);

    map.put("one", 1);
    map.put("two", 2);
    map.put("three", 3);

    assert(map.length == 3);

    int value;
    assert(map.get("two", value));
    assert(value == 2);

    assert(map.containsKey("three"));
    assert(!map.containsKey("four"));

    map.put("two", 22);
    assert(map.get("two", value));
    assert(value == 22);

    assert(map.remove("one"));
    assert(map.length == 2);
    assert(!map.containsKey("one"));

    auto keys = map.keys();
    assert(keys.length == 2);

    auto values = map.values();
    assert(values.length == 2);

    // Test Queue
    auto queue = Queue!int.create();
    assert(queue.empty);

    for (int i = 0; i < 5; i++) {
        queue.push(i);
    }

    assert(queue.length == 5);
    assert(queue.front() == 0);

    queue.pop();
    assert(queue.length == 4);
    assert(queue.front() == 1);

    auto queueArray = queue.toArray();
    assert(queueArray.length == 4);
    assert(queueArray[0] == 1);
    assert(queueArray[3] == 4);
}