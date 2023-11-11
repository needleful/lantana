
module script;

import std.stdio;

import state;

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

State initialize() {
	State s;
	s.name = "<Initial Value>";
	s.event = Event.None;
	return s;
}

bool reload(State* state) {
	writeln("Reloaded library");
	return true;
}

bool update(State* state) {
	state.event = Event.None;
	write("Write something cool: ");
	string input = stdin.readln();
	if(input == "reload\n") {
		state.event = Event.Reload;
	}
	else if(input == "exit\n" || input == "bye\n") {
		writeln("Bye bye!");
		state.event = Event.Exit;
	}
	else if (input == "hello\n") {
		writeln("HELLO!");
	}
	else {
		writef("> %s", input);
	}

	return true;
}