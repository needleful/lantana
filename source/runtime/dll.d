
module runtime.dll;

import runtime;

struct DynamicLibrary {
	import core.runtime;
	alias eventFunc = extern(C) Event function();

	void* library;
	eventFunc update;
	eventFunc quit;
	extern(C) Event function(RuntimeState*) initialize;
	extern(C) Event function(void*) reload;
	extern(C) void* function() getState;

	static auto getProc(alias fn)(void* library) {
		version(Windows) {
			import core.sys.windows.winbase:GetProcAddress;
			return cast(typeof(fn)) GetProcAddress(library, fn.stringof);
		}
		else {
			import core.sys.posix.dlfcn;
			return cast(typeof(fn)) dlsym(library, fn.stringof);
		}
	}

	this(string path) {
		load(path);
	}

	void load(string path) {
		library = Runtime.loadLibrary(path);
		assert(library != null, "Library was not found: "~path);

		initialize = getProc!initialize(library);
		reload = getProc!reload(library);
		update = getProc!update(library);
		quit = getProc!quit(library);
		getState = getProc!getState(library);
		
		assert(initialize != null);
		assert(reload != null);
		assert(update != null);
		assert(quit != null);
		assert(getState != null);
	}

	void unload() {
		if(library) {
			Runtime.unloadLibrary(library);
		}
		library = null;
		initialize = null;
		reload = null;
		update = null;
		quit = null;
	}

	~this() {
		unload();
	}
}
