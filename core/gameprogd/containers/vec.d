module gameprogd.containers.vec;


struct Vec(T)
{
    import core.memory : pureFree, pureMalloc;

    private T* _ptr = null;
    auto ptr() pure { return _ptr; }
    private size_t _length = 0;
    auto length() pure { return _length; }
    private size_t _capacity = 0;
    auto capacity() pure { return _capacity; }

    this(this) @disable;

    @trusted void reset(bool free = true)
    {
        if (free) pureFree(_ptr);
        _ptr = null;
        _length = 0;
        _capacity = 0;
    }

    ~this()
    {
        reset();
    }

    void pushBack(T x)
    {
        if (capacity <= length + 1)
        {
            reserve(length + 1);
        }
        ++_length;
        slice[$-1] = x;
    }

    @trusted void resize(size_t n)
    {
        if (n > length)
        {
            this.reserve(n - length);
            _ptr[length .. n] = T.init;
        }
        _length = n;
    }

    @trusted T[] slice()
    {
        return _ptr[0 .. length];
    }

    @trusted void reserve(size_t n)
    {
        if (n == 0 || T.sizeof == 0) return;
        _capacity = length + n;
        T* old = _ptr;
        const bytes = _capacity * T.sizeof;
        _ptr = cast(T*) pureMalloc(bytes);
        _ptr[0 .. length] = old[0 .. length];
        pureFree(old);
    }
}

nothrow @safe @nogc unittest
{
    Vec!int v;

    v.pushBack(1);
    v.pushBack(2);
    static const a1 = [1, 2];
    assert(v.slice == a1);

    v.resize(3);
    static const a2 = [1, 2, int.init];
    assert(v.slice == a2);

    v.resize(1);
    static const a3 = [1];
    assert(v.slice == a3);
}

nothrow @nogc unittest
{
    Vec!(int*) v;
    v.resize(2);
    static const a1 = [null, null];
    assert(v.slice == a1);

    int x = 1;
    v.pushBack(&x);
    assert(v.slice[$-1] == &x);
}
