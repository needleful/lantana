
module game.dllmain;

import std.stdio;
import state;

import runtime.sdl;

shared static this() {
	writeln("Loading library");
}

shared static ~this() {
	writeln("Unloaded library");
}

version(Windows)
{
	import core.sys.windows.dll;
	mixin SimpleDllMain;
}

extern(C):

Event initialize(State* s) {
	try{
		s.window = Window(700, 700, "Dynamic Engine");
	}
	catch (Throwable e) {
		writeln(e);
		return Event.Exit;
	}
	return Event.None;
}

Event reload(State* s) {
	writeln("Reloaded library");
	return Event.None;
}

Event update(State* s, SDL_Event e) {
	while(true) {
		while(SDL_PollEvent(&e)) {
			switch(e.type) {
			case SDL_QUIT:
				return Event.Exit;
			case SDL_KEYDOWN:
				if (e.key.keysym.sym == SDLK_r)
					return Event.Reload;
				break;
			default:
				break;
			}
		}
	}
	//Thread.sleep(dur!"msecs"(16));
}

Event quit(State* s) {
	return Event.Exit;
}