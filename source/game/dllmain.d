
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
	return Event.None;
}

Event reload(State* s) {
	s.window.setColor(255, 0, 0);
	s.window.redraw();
	writeln("Reloaded library");
	return Event.None;
}

Event update(State* s, SDL_Event e) {
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
	return Event.None;
}

Event quit(State* s) {
	return Event.Exit;
}