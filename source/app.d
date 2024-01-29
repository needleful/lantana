
import std.stdio;

import runtime;
import state;

int main()
{
	DynamicLibrary lib = DynamicLibrary("script.dll");
	
	State state;
	Event r = lib.initialize(&state);
	if (r == Event.Exit) {
		writeln("Game failed to initialize. Exiting now.");
		return 1;
	}

	SDL_Event se;
	for(Event e = Event.None; e != Event.Exit; e = lib.update(&state, se)){
		if (e == Event.Reload) {
			lib.unload();
			import std.process;
			Pid pid = spawnProcess(["dub", "build", "--config=script"]);
			wait(pid);
			lib.load("script.dll");
			if(lib.reload(&state) == Event.Exit) {
				writeln("Failed to reload library");
				e = Event.Exit;
			}
		}
	}
	lib.quit(&state);
	return 0;
}
