
module game.main;

import core.thread.osthread;
import core.time;
import std.stdio;

import game.ui.core;

import lantana.core;
import lantana.runtime;

struct GameState {
	Descriptor descriptor;
	RuntimeState* runtime;
	nk_sdl nkui;
	nk_context* ctx;
    nk_colorf bg = {0.2, 0.2, 0.2 ,1};

	int counter = 0;

	ref Window window() {
		return runtime.window;
	}

	ref BaseRegion memory() {
		return runtime.memory;
	} 
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
	gs.ctx = nk_sdl_init(gs.nkui, gs.window().sdlWindow);
	nk_font_atlas* atlas;
	nk_sdl_font_stash_begin(gs.nkui, &atlas);
	nk_sdl_font_stash_end(gs.nkui);
}


enum MAX_VERTEX_MEMORY = 512 * 1024;
enum MAX_ELEMENT_MEMORY = 128 * 1024;

Event runGame() {

	while(true) {
        nk_input_begin(gs.ctx);
		SDL_Event event;
		while(SDL_PollEvent(&event)) {
			nk_sdl_handle_event(gs.nkui, &event);

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
        nk_sdl_handle_grab(gs.nkui); /* optional grabbing behavior */
        nk_input_end(gs.ctx);

        if (nk_begin(gs.ctx, "Demo", nk_rect(50, 50, 230, 250),
            NK_WINDOW_BORDER|NK_WINDOW_MOVABLE|NK_WINDOW_SCALABLE|
            NK_WINDOW_MINIMIZABLE|NK_WINDOW_TITLE))
        {
            enum {EASY, HARD};
            static int op = EASY;
            static int property = 20;

            nk_layout_row_static(gs.ctx, 30, 80, 1);
            if (nk_button_label(gs.ctx, "button"))
                writeln("button pressed!");
            nk_layout_row_dynamic(gs.ctx, 30, 2);
            if (nk_option_label(gs.ctx, "easy", op == EASY)) op = EASY;
            if (nk_option_label(gs.ctx, "hard", op == HARD)) op = HARD;
            nk_layout_row_dynamic(gs.ctx, 22, 1);
            nk_property_int(gs.ctx, "Compression:", 0, &property, 100, 10, 1);

            nk_layout_row_dynamic(gs.ctx, 20, 1);
            nk_label(gs.ctx, "background:", NK_TEXT_LEFT);
            nk_layout_row_dynamic(gs.ctx, 25, 1);
            if (nk_combo_begin_color(gs.ctx, nk_rgb_cf(gs.bg), nk_vec2(nk_widget_width(gs.ctx),400))) {
                nk_layout_row_dynamic(gs.ctx, 120, 1);
                gs.bg = nk_color_picker(gs.ctx, gs.bg, NK_RGBA);
                nk_layout_row_dynamic(gs.ctx, 25, 1);
                gs.bg.r = nk_propertyf(gs.ctx, "#R:", 0, gs.bg.r, 1.0f, 0.01f,0.005f);
                gs.bg.g = nk_propertyf(gs.ctx, "#G:", 0, gs.bg.g, 1.0f, 0.01f,0.005f);
                gs.bg.b = nk_propertyf(gs.ctx, "#B:", 0, gs.bg.b, 1.0f, 0.01f,0.005f);
                gs.bg.a = nk_propertyf(gs.ctx, "#A:", 0, gs.bg.a, 1.0f, 0.01f,0.005f);
                nk_combo_end(gs.ctx);
            }
        }
        nk_end(gs.ctx);

        glClearColor(gs.bg.r, gs.bg.g, gs.bg.b, gs.bg.a);
		gs.window().beginFrame();
		nk_sdl_render(gs.nkui, NK_ANTI_ALIASING_ON, MAX_VERTEX_MEMORY, MAX_ELEMENT_MEMORY);
		gs.window().endFrame();
		Thread.sleep(dur!"msecs"(16));
	}
}