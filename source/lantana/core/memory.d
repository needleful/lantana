module lantana.core.memory;

import std.conv : emplace;
import std.traits;
import core.memory;

debug import std.stdio;

struct BaseRegion
{
	import std.experimental.allocator.mmap_allocator;
	Region region;

	this(size_t p_capacity) @nogc
	{
		ubyte* data = cast(ubyte*) MmapAllocator.instance.allocate(p_capacity).ptr;

		assert(data != null, "Failed to get memory for region");
		region = Region(data, p_capacity);
	}

	~this() @nogc
	{
		if (region.data) {
			size_t cap = region.capacity();
			region.disable();
			MmapAllocator.instance.deallocate(cast(void[]) region.data[0..cap]);
		}
	}

	SubRegion provideRemainder() 
	{
		size_t spaceRemaining = region.capacity() - region.spaceUsed();
		return SubRegion(spaceRemaining, this);
	}

	alias region this;

	Region* ptr() return @nogc nothrow
	{
		return &region;
	}
}

struct SubRegion
{
	Region region;

	this(size_t p_capacity, ref BaseRegion p_parent) @nogc
	{
		ubyte* data = p_parent.makeList!ubyte(p_capacity).ptr;
		assert(data != null, "Failed to get memory for region");
		region = Region(data, p_capacity);
	}

	~this()
	{
		region.disable();
	}

	alias region this;

	Region* ptr() return @nogc nothrow
	{
		return &region;
	}
}

/++ A Region of memory for dumb data with quick allocation and clearing.
   note: when Region space is freed, it does not call any destructors.
   It is the responsibility of the calling code to call destroy()
   on any objects that manage other resources.
+/
struct Region
{
	enum minimumSize = size_t.sizeof*2;

	ubyte* data;

	this(ubyte* p_data, size_t p_capacity) @nogc
	{
		assert(p_capacity > minimumSize);
		data = p_data;
		setCapacity(p_capacity);
		setSpaceUsed(2*size_t.sizeof);

		debug writef("Creating Region with %u bytes\n", cast(ulong) capacity());
	}

	void disable() @nogc
	{
		if(data) {
			debug writef("Deleting Region with %u/%u bytes allocated\n", cast(ulong) spaceUsed(), cast(ulong) capacity());
			setCapacity(0);
			setSpaceUsed(0);
			data = null;
		}
	}

	/+
	 +  User-friendly methods for allocation 
	 +/
	T[] makeList(T)(size_t count)
	{
		//debug printf("MEM: Creating %s[%u]\n", T.stringof.ptr, count);
		//return (cast(T*)allocAligned!(AlignT!T)(T.sizeof * count))[0..count];
		return (cast(T*)alloc(T.sizeof*count))[0..count];
	}

	OwnedList!T makeOwnedList(T)(uint p_size)
	{
		//return OwnedList!T((cast(T*)allocAligned!(AlignT!T)(T.sizeof * p_size)), p_size);
		return OwnedList!T((cast(T*)alloc(T.sizeof * p_size)), p_size);
	}

	auto make(T, A...)(auto ref A args)
	{
		//debug printf("MEM: Creating instance of %s\n", T.stringof.ptr);
		static if(is(T == class))
		{
			//void[] buffer = allocAligned!(AlignT!T)(T.sizeof)[0..T.sizeof];
			void[] buffer = cast(void[]) alloc(T.sizeof)[0..T.sizeof];
			assert(buffer.ptr != null, "Failed to allocate memory");
			return emplace!(T, A)(buffer, args);
		}
		else
		{
			//T *ptr = cast(T*) allocAligned!(AlignT!T)(T.sizeof);
			T *ptr = cast(T*) alloc(T.sizeof);
			assert(ptr != null, "Failed to allocate memory");
			return emplace!(T, A)(ptr, args);
		}
	}

	T copy(T)(T p_string)
		if(isSomeString!T)
	{
		return cast(T) copyList(p_string);
	}

	T[] copyList(T)(immutable(T)[] p_list)
	{
		auto newList = makeList!T(p_list.length);
		newList.readData(p_list);
		return newList;
	}

	/// Wipe all data from the stack
	void wipe() @nogc nothrow
	{
		setSpaceUsed(minimumSize);
	}

	// Wipe all data except for `used` bytes.
	// Make sure you know what you're doing!
	void wipeAllBut(size_t used) @nogc nothrow
	{
		assert(used >= minimumSize && used <= spaceUsed());
		setSpaceUsed(used);
	}

	private void* alloc(size_t bytes) @nogc
	{
		if((bytes + spaceUsed()) > capacity())
		{
			import std.stdio;
			printf("Exceeded memory limits: %llu > %llu\n", cast(ulong) bytes + spaceUsed(), cast(ulong) capacity());
			debug
				assert(false, "Out of memory");
			else
				return null;
		}
		void* result = cast(void*)(&data[spaceUsed]);
		setSpaceUsed(spaceUsed + bytes);

		return result;
	}

	private void* allocAligned(uint alignment)(size_t bytes) @nogc
	{
		ulong address = ((cast(ulong)data)+spaceUsed());
		auto alignShift = address % alignment;
		alignShift = (alignment - alignShift) % alignment;

		assert((address + alignShift) % alignment == 0);
		assert(alignShift <= alignment);

		void* ptr = alloc(bytes + alignShift);

		return &ptr[alignShift];
	}

	private bool remove(void* data) @nogc nothrow
	{
		// Regions don't remove things
		return false;
	}

	size_t capacity() @nogc const nothrow
	{
		return (cast(size_t*)data)[0];
	}

	size_t spaceUsed() @nogc const nothrow
	{
		return (cast(size_t*)data)[1];
	}

	private void setCapacity(size_t val) @nogc nothrow
	{
		(cast(size_t*)data)[0] = val;
	}

	private void setSpaceUsed(size_t val) @nogc nothrow
	{
		(cast(size_t *) data)[1] = val;
	}
}