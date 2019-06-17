module gameprogd.containers.vec;

import stdx.allocator.mallocator : Mallocator;

/// Dynamic array similar to std::vector<T, Allocator> in C++
struct Vec(T, Allocator = Mallocator)
{
    Allocator _allocator;;

    private T* _ptr = null;
    auto ptr() pure { return _ptr; }
    private size_t _length = 0;
    auto length() pure { return _length; }
    private size_t _capacity = 0;
    auto capacity() pure { return _capacity; }

    this(this) @disable;

    @trusted void reset(bool free = true)
    {
        if (free) _allocator.deallocate(slice);
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

    @trusted void remove(size_t i)
    {
        assert(i < length, "out of bounds");
        // NOTE: why range violation without this?
        if (i == 0)
        {
            foreach (j; 0 .. length - 1)
            {
                _ptr[j] = _ptr[j + 1];
            }
        }
        else
        {
            _ptr[i .. length - 1] = _ptr[i + 1 .. length];
        }
        --_length;
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

    void shrink()
    {
        this.realloc(length);
    }

    void reserve(size_t n)
    {
        const c = length + n;
        if (c > _capacity) this.realloc(c);
    }

    @trusted void realloc(size_t n)
    {
        auto b = (cast(void*)_ptr)[0 .. _capacity * T.sizeof];
        auto result = _allocator.reallocate(b, n * T.sizeof);
        assert(result, "reallocation failed");

        _ptr = cast(typeof(_ptr)) b.ptr;
        _capacity = n;
        if (_length > n) _length = n;
    }
}

/// basic usage with simple value type
nothrow @safe @nogc unittest
{
    Vec!int v;

    v.pushBack(1);
    v.pushBack(2);
    v.pushBack(3);
    static const a1 = [1, 2, 3];
    assert(v.slice == a1);

    v.remove(0);
    static const a2 = [2, 3];
    assert(v.slice == a2);

    v.remove(1);
    static const a3 = [2];
    assert(v.slice == a3);

    v.resize(3);
    static const a4 = [2, int.init, int.init];
    assert(v.slice == a4);

    v.resize(1);
    static const a5 = [2];
    assert(v.slice == a5);

    v.shrink();
    assert(v.capacity == v.length);
}

/// basic usage with simple pointer type
nothrow @nogc @system unittest
{
    Vec!(int*) v;
    v.resize(2);
    static const a1 = [null, null];
    assert(v.slice == a1);

    int x = 1;
    v.pushBack(&x);
    assert(v.slice[$-1] == &x);
}


/**
   Vec with small buffer optimization

   It allocates at least N elements on the stack region.
   If the stack is run out, its allocator fallbacks into `Allocator`.

   see also
   - https://github.com/facebook/folly/blob/master/folly/docs/small_vector.md
   - http://llvm.org/docs/ProgrammersManual.html#llvm-adt-smallvector-h

   the stack size T.sizeof * (N + alignment - 1) is documented at
   stdx.allocator.building_blocks.region.InSituRegion
*/
struct SmallVec(T, size_t N, Allocator = Mallocator)
{
    import stdx.allocator.showcase : StackFront;

    enum stackSize = T.sizeof * (N + Allocator.alignment - 1);

    Vec!(T, StackFront!(stackSize, Allocator)) _base;

    alias _base this;

    bool onStack()()
    {
        import stdx.allocator.internal : Ternary;
        return _capacity > 0 &&
            _base._allocator.primary.owns(_base._ptr[0 .. 1]) == Ternary.yes;
    }
}

/// usage
nothrow @nogc @system unittest
{
    import std.typecons : tuple;
    enum N = 10;
    foreach (t; tuple(1.0f, 1.0))
    {
        SmallVec!(typeof(t), N) v;
        v.pushBack(1);
        v.pushBack(2);
        // static const a = [1, 2];
        assert(v.slice[0] == 1);
        assert(v.slice[1] == 2);
        assert(v.length == 2);
        assert(v.onStack);

        v.resize(N);
        assert(v.onStack);

        v.resize(N + 1);
        // allocated at heap
        assert(!v.onStack);
    }
}
