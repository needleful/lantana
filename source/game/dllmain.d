
module game.dllmain;

import std.stdio;

import game.main;
import lantana.types.meta;
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
	import core.sys.windows.windows;
	mixin SimpleDllMain;
	void messageBox(wstring msg) {
		MessageBoxW(null, msg.ptr, null, MB_ICONEXCLAMATION);
	}
}
else {
	void messageBox(wstring msg) {
		writefln("-- %s", msg);
	}
}

export extern(C):

Event initialize(RuntimeState* rs) {
	return initGame(rs);
}

Event reload(GameState* p_gs) {
	auto desc = Descriptor.of!GameState();
	if(p_gs.descriptor != desc) {
		writefln("GameState structure changed! %s versus %s", desc, p_gs.descriptor);
		return Event.Exit;
	}
	gs = p_gs;

	import bindbc.opengl;
	import std.format;
	GLSupport glResult = loadOpenGL();
	assert(glResult >= GLSupport.gl43, format("OpenGL 4.3 or higher required! Got %s", glResult));

	writeln("Reloaded library");
	return Event.None;
}

Event update() {
	try {
		assert(glDepthMask);
		return runGame();
	}
	catch (Throwable e) {
		import std.format;
			messageBox(format("There was an error:\r\n%s\0"w, e));
			return Event.Exit;
	}
}

Event quit() {
	return Event.Exit;
}

GameState* getState(){
	gs.descriptor = Descriptor.of!GameState();
	return gs;
}