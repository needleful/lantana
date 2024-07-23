
module lantana.runtime.dll;

import lantana.runtime;

struct DynamicLibrary {
	import core.runtime;
	alias eventFunc = extern(C) Event function();

	void* library;
	eventFunc update;
	eventFunc quit;
	extern(C) Event function(RuntimeState*) initialize;
	extern(C) Event function(void*) reload;
	extern(C) void* function() getState;

	this(string path) {
		load(path);
	}

	void load(string path) {
		library = Runtime.loadLibrary(path);
		assert(library != null);

		import core.sys.windows.winbase:GetProcAddress;
		initialize = cast(typeof(initialize)) GetProcAddress(library, "initialize");
		reload = cast(typeof(reload)) GetProcAddress(library, "reload");
		update = cast(typeof(update)) GetProcAddress(library, "update");
		quit = cast(typeof(quit)) GetProcAddress(library, "quit");
		getState = cast(typeof(getState)) GetProcAddress(library, "getState");
		
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