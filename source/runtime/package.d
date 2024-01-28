
module runtime;
import state;
public import runtime.sdl;


struct DynamicLibrary {
	import core.runtime;
	alias stateFunc = extern(C) Event function(State*);
	alias eventFunc = extern(C) Event function(State*, SDL_Event e);

	void* library;
	stateFunc initialize;
	stateFunc reload;
	eventFunc update;
	stateFunc quit;

	this(string path) {
		load(path);
	}

	void load(string path) {
		library = Runtime.loadLibrary(path);
		assert(library != null);

		import core.sys.windows.winbase:GetProcAddress;
		initialize = cast(stateFunc) GetProcAddress(library, "initialize");
		reload = cast(stateFunc) GetProcAddress(library, "reload");
		update = cast(eventFunc) GetProcAddress(library, "update");
		quit = cast(stateFunc) GetProcAddress(library, "quit");
		
		assert(initialize != null);
		assert(reload != null);
		assert(update != null);
		assert(quit != null);
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