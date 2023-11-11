import std.stdio;

import state;

struct DynamicScript {
	import core.runtime;
	alias initFunc = extern(C) State function();
	alias stateFunc = extern(C) bool function(State*);

	void* library;
	initFunc initialize;
	stateFunc reload;
	stateFunc update;

	this(string path) {
		load(path);
	}

	void load(string path) {
		library = Runtime.loadLibrary(path);

		import core.sys.windows.winbase:GetProcAddress;
		initialize = cast(initFunc) GetProcAddress(library, "initialize");
		reload = cast(stateFunc) GetProcAddress(library, "reload");
		update = cast(stateFunc) GetProcAddress(library, "update");
		
		assert(initialize != null);
		assert(reload != null);
		assert(update != null);
	}

	void clear() {
		if(library) {
			Runtime.unloadLibrary(library);
		}
		library = null;
		initialize = null;
		reload = null;
		update = null;
	}

	~this() {
		clear();
	}
}

void main()
{
	DynamicScript lib = DynamicScript("script.dll");

	State state = lib.initialize();
	while(state.event != Event.Exit) {
		lib.update(&state);
		if(state.event == Event.Reload) {
			lib.clear();
			import std.process;
			Pid pid = spawnProcess(["dub", "build", "--config=script"]);
			wait(pid);
			lib.load("script.dll");
		}
	}
}
