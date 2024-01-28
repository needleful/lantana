
import std.stdio;

import runtime;
import state;

int main()
{
	DynamicLibrary lib = DynamicLibrary("script.dll");
	
	State state;
	state.window = Window.create();
	Event r = lib.initialize(&state);
	if (r == Event.Exit) {
		writeln("Game failed to initialize. Exiting now.");
		return 1;
	}

	bool quit = false;
	while(!quit){
		SDL_Event se;
		while(SDL_PollEvent(&se)) {
			Event le = lib.update(&state, se);
			if (le == Event.Reload) {
				lib.unload();
				import std.process;
				Pid pid = spawnProcess(["dub", "build", "--config=script"]);
				wait(pid);
				lib.load("script.dll");
				if(lib.reload(&state) == Event.Exit) {
					writeln("Failed to reload library");
					quit = true;
				}
			}
			else if(le == Event.Exit) {
				quit = true;
			}
		}
	}
	lib.quit(&state);
	return 0;
}
