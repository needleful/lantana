
import std.stdio;

import runtime;
import runtime.dll;

static RuntimeState state;

int compile() {
	import std.process;
	Pid pid = spawnProcess(["dub", "build", "--config=script"]);
	return wait(pid);
}

int main()
{
	assert(compile() == 0);
	DynamicLibrary game = DynamicLibrary("script.dll");
	Event r = game.initialize(&state);

	if (r == Event.Exit) {
		writeln("Game failed to initialize. Exiting now.");
		return 1;
	}

	for(Event e = Event.None; e != Event.Exit; e = game.update()){
		if (e == Event.Reload) {
			void* gameState = game.getState();
			game.unload();
			
			if(compile() != 0) {
				writeln("Failed to compile script!");
			}
			
			game.load("script.dll");
			if(game.reload(gameState) == Event.Exit) {
				writeln("Failed to reload library");
				return 1;
			}
		}
	}
	game.quit();
	return 0;
}
