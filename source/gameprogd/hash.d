module gameprogd.hash;

// A variant of the FNV-1a (64) hashing algorithm.
auto genFNV1a64Hash(T : const(char)[])(T value) pure nothrow @nogc @trusted
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

auto genFNV1a64Hash(T)(const auto ref T value) pure nothrow @nogc @trusted
{
    import std.traits : hasMember;
    const p = cast(const(char)*) &value;
    const n = T.sizeof / char.sizeof;
    return genFNV1a64Hash(p[0 .. n]);
}

@safe @nogc unittest
{
    import std.typecons : tuple;

    assert(genFNV1a64Hash("hihi") == genFNV1a64Hash("hihi"));
    assert(genFNV1a64Hash("hihi") != genFNV1a64Hash("hih"));

    assert(genFNV1a64Hash(1) == genFNV1a64Hash(1));
    assert(genFNV1a64Hash(1) != genFNV1a64Hash(2));

    assert(genFNV1a64Hash(tuple("foo", 1)) == genFNV1a64Hash(tuple("foo", 1)));
    assert(genFNV1a64Hash(tuple("foo", 1)) != genFNV1a64Hash(tuple("foo", 2)));
}

@safe @nogc unittest
{
    import std.typecons : Tuple;
    import std.traits : hasMember;
    struct A
    {
        int[] x;
        double y;
    }

    static assert(!hasMember!(int[], "tupleof"));
    static assert(hasMember!(Tuple!(int, double), "tupleof"));
    static assert(hasMember!(A, "tupleof"));
}
