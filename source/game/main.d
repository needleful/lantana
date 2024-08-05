
module game.main;

import core.thread.osthread;
import core.time;
import std.stdio;

import game.ui.core;
import game.ui.simple;

import lantana.core;
import lantana.runtime;

struct GameState {
	Descriptor descriptor;
	RuntimeState* runtime;
	nk_sdl nkui;
	UIState uiState;

	int counter = 0;

	ref Window window() {
		return runtime.window;
	}

	ref BaseRegion memory() {
		return runtime.memory;
	} 
}

struct UIState {
	enum Op {Trivial, Easy, Hard};
	nk_colorf bg = {0.2, 0.2, 0.2 ,1};
	int property = 20;
	Op op = Op.Easy;
}

GameState *gs;

Event initGame(RuntimeState* rs) {
	rs.window = Window(700, 700, "Dynamic Engine");
	rs.memory = BaseRegion(1024*1024);
	gs = rs.memory.make!GameState();
	if(!gs) {
		writeln("Could not allocate game state!");
		return Event.Exit;
	}
	gs.runtime = rs;
	initUI;
	return Event.None;
}

void initUI() {
	nk_sdl_init(&gs.nkui, gs.window().sdlWindow);
	nk_font_atlas* atlas;
	nk_sdl_font_stash_begin(&gs.nkui, &atlas);
	nk_sdl_font_stash_end(&gs.nkui);
}

enum MAX_VERTEX_MEMORY = 512 * 1024;
enum MAX_ELEMENT_MEMORY = 128 * 1024;

Event runGame() {
	Event rtEvent = Event.None;
	while(rtEvent == Event.None) {
		nk_input_begin(&gs.nkui.ctx);
		SDL_Event event;
		while(SDL_PollEvent(&event)) {
			nk_sdl_handle_event(&gs.nkui, &event);

			switch(event.type) {
			case SDL_QUIT:
				rtEvent = Event.Exit;
				break;
			case SDL_KEYDOWN:
				if (event.key.keysym.sym == SDLK_SPACE)
					writefln("I'm HAPPY times %d", ++gs.counter*gs.counter);
				break;
			default:
				break;
			}
		}
		nk_sdl_handle_grab(&gs.nkui);
		nk_input_end(&gs.nkui.ctx);

		with(UI(&gs.nkui, "Status", nk_rect(50, 50, 230, 250),
			NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_SCALABLE|
			NK_WINDOW_MINIMIZABLE|NK_WINDOW_TITLE)) 
		{
			grabHandle();
			endInput();
			if(valid) {
				flexRow(30, 2);
				label("Hello from the game");
				if (button("Reload")) {
					rtEvent = Event.Reload;
				}
				flexRow(22);
				slider("Gamer juice:", 0, gs.uiState.property, 10000, 10, 1);
				if (gs.uiState.property > 100) {
					radio(gs.uiState.op, 30);
				}

				flexRow(20);
				label("Window color:", NK_TEXT_LEFT);
				flexRow(25);
				with(combo(nk_rgb_cf(gs.uiState.bg), nk_vec2(width(),400))) {
					if(valid) {
						flexRow(120);
						colorPicker(gs.uiState.bg, NK_RGB);
						flexRow(25);
						slider("#R:", 0, gs.uiState.bg.r, 1.0f, 0.01f,0.005f);
						slider("#G:", 0, gs.uiState.bg.g, 1.0f, 0.01f,0.005f);
						slider("#B:", 0, gs.uiState.bg.b, 1.0f, 0.01f,0.005f);
						slider("#A:", 0, gs.uiState.bg.a, 1.0f, 0.01f,0.005f);
					}
				}
			}
		}

		glClearColor(gs.uiState.bg.r, gs.uiState.bg.g, gs.uiState.bg.b, gs.uiState.bg.a);
		gs.window().beginFrame();
		nk_sdl_render(&gs.nkui, NK_ANTI_ALIASING_ON, MAX_VERTEX_MEMORY, MAX_ELEMENT_MEMORY);
		gs.window().endFrame();
		Thread.sleep(dur!"msecs"(16));
	}
	return rtEvent;
}