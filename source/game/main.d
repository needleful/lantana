
module game.main;

import core.thread.osthread;
import core.time;
import std.stdio;

import lantana.core;
import lantana.runtime;

struct GameState {
	Descriptor descriptor;
	RuntimeState* runtime;
	int counter = 0;

	ref Window window() {
		return runtime.window;
	}

	ref BaseRegion memory() {
		return runtime.memory;
	} 
}

GameState *gs;

Event runGame() {
	while(true) {
		assert(glDepthMask);
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
		glClearColor(1, 1, 1, 1);
		gs.window().beginFrame();
		gs.window().endFrame();
		Thread.sleep(dur!"msecs"(16));
	}
}