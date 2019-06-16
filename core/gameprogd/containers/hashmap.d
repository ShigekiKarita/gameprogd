module gameprogd.containers.hashmap;

import core.memory : pureFree, pureMalloc;
import gameprogd.containers.vec : Vec;

// A variant of the FNV-1a (64) hashing algorithm.
auto genHash(T : const(char)[])(T value) pure nothrow @nogc @trusted
{
    // import containers.internal.hash : generateHash;
    // return generateHash(value);
    hash_t h = 0xcbf29ce484222325;
		foreach (const ubyte c; cast(ubyte[]) value)
		{
        h ^= ((c - ' ') * 13);
        h *= 0x100000001b3;
		}
    return h;
}

auto genHash(T)(const auto ref T value) pure nothrow @nogc @trusted
{
    const p = cast(const(char)*) &value;
    const n = T.sizeof / char.sizeof;
    return genHash(p[0 .. n]);
}

@safe @nogc unittest
{
    import std.typecons : tuple;

    assert(genHash("hihi") == genHash("hihi"));
    assert(genHash("hihi") != genHash("hih"));

    assert(genHash(1) == genHash(1));
    assert(genHash(1) != genHash(2));

    assert(genHash(tuple("foo", 1)) == genHash(tuple("foo", 1)));
    assert(genHash(tuple("foo", 1)) != genHash(tuple("foo", 2)));
}

struct HashMap(K, V, alias hashFun = genHash)
{
    struct Pair
    {
        K key;
        V value;
    }

    const size_t capacity = 10000;

    private size_t _length = 0;
    pure length() { return _length; }

    alias Storage = Vec!Pair;
    Vec!(Storage*) _storages;

    this(this) @disable;

    @trusted ~this()
    {
        foreach (ref p; this._storages.slice)
        {
            pureFree(p);
            p = null;
        }
    }

    @trusted void resizeIfLonger(size_t n)
    {
        if (n > this.capacity || this._storages.length >= this.capacity) return;
        auto prev = this._storages.length;
        this._storages.resize(n + 1);
        foreach (ref s; this._storages.slice[prev..$])
        {
            s = cast(Storage*) pureMalloc(Storage.sizeof);
            s.reset(false);
        }
    }

    Storage* storageOf(K k)
    {
        const i = hashFun(k) % this.capacity;
        this.resizeIfLonger(i);
        return this._storages.slice[i];
    }

    ref Pair insert(K k, V v)
    {
        auto s = this.storageOf(k);
        foreach (ref p; s.slice)
        {
            if (p.key == k)
            {
                p.value = v;
                return p;
            }
        }
        ++this._length;
        s.pushBack(Pair(k, v));
        return s.slice[$-1];
    }

    ref opIndexAssign(V v, K k)
    {
        return insert(k, v);
    }

    // FIXME: explicit @nogc is required for lazy V
    ref V get(K k, V defaultValue)
    {
        foreach (ref p; this.storageOf(k).slice)
        {
            if (p.key == k) return p.value;
        }
        return this.insert(k, defaultValue).value;
    }

    ref V get(K k)
    {
        foreach (ref p; this.storageOf(k).slice)
        {
            if (p.key == k) return p.value;
        }
        assert(false, "key not found");
    }

    ref opIndex(K k)
    {
        return get(k);
    }

    bool contains(K k)
    {
        foreach (ref p; this.storageOf(k).slice)
        {
            if (p.key == k) return true;
        }
        return false;
    }

    bool opBinaryRight(string s)(K k) if (s == "in")
    {
        return this.contains(k);
    }

    auto range()
    {
        return HashMapRange(this._storages.slice);
    }

    auto opSlice()
    {
        return this.range();
    }

    struct HashMapRange
    {
        Pair[] curr;
        Storage*[] nexts;

        this(Storage*[] ss)
        {
            foreach (i, s; ss)
            {
                if (s.length > 0)
                {
                    curr = s.slice;
                    nexts = ss[i + 1 .. $];
                    break;
                }
            }
        }

        auto front()
        {
            return curr[0];
        }

        bool empty()
        {
            return curr.length == 0;
        }

        void popFront()
        {
            if (empty) return;
            if (curr.length > 1)
            {
                curr = curr[1 .. $];
                return;
            }
            else
            {
                foreach (i, s; nexts)
                {
                    if (s.length > 0)
                    {
                        curr = s.slice;
                        nexts = nexts[i + 1 .. $];
                        return;
                    }
                }
            }
            curr = [];
            nexts = [];
        }
    }
}

nothrow @safe @nogc unittest
{
    static const x = [1, 2];
    assert(x[$..$] == []);
}

nothrow @safe @nogc
unittest
{
    HashMap!(int, double) hm = { capacity: 2 };
    hm.insert(0, 0.0);
    hm[1] = 0.0;
    hm[1] = 0.1;
    hm[2] = 0.0;
    assert(hm.contains(0));
    assert(hm[0] == 0.0);
    assert(1 in hm);
    assert(hm.get(1) == 0.1);
    assert(2 in hm);
    assert(hm[2] == 0.0);
    assert(100 !in hm);
    assert(hm.get(100, -1) == -1);
    assert(hm.length == 4);

    import std.range;
    static assert(isInputRange!(typeof(hm.range())));
    size_t n = 0;
    foreach (e; hm[]) {
        ++n;
    }
    assert(hm.length == n);
}

