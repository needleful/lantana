
module game.dllmain;

import std.stdio;
import game;
import runtime;

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

export extern(C):

Event initialize(RuntimeState* rs) {
	gs = rs.memory.make!GameState();
	if(!gs) {
		writeln("Could not allocate game state!");
		return Event.Exit;
	}
	return Event.None;
}

Event reload(GameState* p_gs) {
	auto desc = Descriptor.of!GameState();
	if(p_gs.descriptor != desc) {
		writefln("GameState structure changed! %s versus %s", desc, p_gs.descriptor);
		return Event.Exit;
	}
	gs = p_gs;
	writeln("Reloaded library");
	return Event.None;
}

Event update() {
	while(true) {
		SDL_Event event;
		while(SDL_PollEvent(&event)) {
			switch(event.type) {
			case SDL_QUIT:
				return Event.Exit;
			case SDL_KEYDOWN:
				if (event.key.keysym.sym == SDLK_r)
					return Event.Reload;
				if (event.key.keysym.sym == SDLK_SPACE)
					writefln("I'm HAPPY times %d", ++gs.counter*gs.counter);
				break;
			default:
				break;
			}
		}
	}
	Thread.sleep(dur!"msecs"(16));
}

Event quit() {
	return Event.Exit;
}

GameState* getState(){
	gs.descriptor = Descriptor.of!GameState();
	return gs;
}