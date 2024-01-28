
module runtime.sdl;

public import bindbc.sdl;

struct Window {
	// Private so my dumb brain doesn't try reading these from the DLL
	private SDL_Window* window;
	private SDL_Surface* surface;

	static Window create() {
		import std.format;
		import std.string;

		Window w;
		if(SDL_Init(SDL_INIT_VIDEO) < 0) {
			throw new Exception(format("Could not initialize SDL: %s", fromStringz(SDL_GetError())));
		}
		w.window = SDL_CreateWindow( "Dynamic Engine", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED,
			700, 600, SDL_WINDOW_SHOWN);
		w.surface = SDL_GetWindowSurface(w.window);
		return w;
	}

	void redraw() {
		SDL_UpdateWindowSurface(window);
	}

	void setColor(ubyte red, ubyte green, ubyte blue) {
		SDL_FillRect( surface, null, SDL_MapRGB( surface.format, red, green, blue ) );
	}

	~this() {
		if(window) {
			SDL_DestroyWindow(window);
			SDL_Quit();
		}
	}
}