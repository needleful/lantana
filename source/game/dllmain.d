
module game.dllmain;

import std.stdio;

import game.main;
import lantana.core;
import lantana.runtime;

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
	rs.window = Window(700, 700, "Dynamic Engine");
	assert(glDepthMask);
	rs.memory = BaseRegion(1024);
	gs = rs.memory.make!GameState();
	if(!gs) {
		writeln("Could not allocate game state!");
		return Event.Exit;
	}
	gs.runtime = rs;
	return Event.None;
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
	assert(glDepthMask);
	return runGame();
}

Event quit() {
	return Event.Exit;
}

GameState* getState(){
	gs.descriptor = Descriptor.of!GameState();
	return gs;
}