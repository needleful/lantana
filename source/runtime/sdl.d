
module runtime.sdl;

public import bindbc.opengl;
public import bindbc.sdl;

struct Window {
	// Private so my dumb brain doesn't try reading these from the DLL
	SDL_Window* sdlWindow;
	SDL_GLContext glContext;

	this(uint width, uint height, const(char*) name) {
		import std.format;
		import std.string;

    	SDL_SetHint(SDL_HINT_VIDEO_HIGHDPI_DISABLED, "0");
		if(SDL_Init(SDL_INIT_VIDEO|SDL_INIT_TIMER|SDL_INIT_EVENTS) < 0) {
			throw new Exception(format("Could not initialize SDL: %s", fromStringz(SDL_GetError())));
		}
		SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);
		SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 3);
		SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

		sdlWindow = SDL_CreateWindow(
			name, 
			cast(int)SDL_WINDOWPOS_CENTERED, 
			cast(int)SDL_WINDOWPOS_CENTERED, 
			width, height, 
			SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
		glContext = SDL_GL_CreateContext(sdlWindow);
		
		GLSupport glResult = loadOpenGL();
		assert(glResult >= GLSupport.gl43, format("OpenGL 4.3 or higher required! Got %s", glResult));
		
		glFrontFace(GL_CCW);
		glDepthFunc(GL_LESS);
		glClearColor(1, 1, 1, 1);
		glClearDepth(1.0f);
	}

	void beginFrame(bool clear_color = true)() 
	{
		glDepthMask(GL_TRUE);
		assert(glGetError() == GL_NO_ERROR);
		static if(clear_color)
		{
			glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		}
		else
		{
			glClear(GL_DEPTH_BUFFER_BIT);
		}
		assert(glGetError() == GL_NO_ERROR);
	}

	void endFrame() 
	{
		SDL_GL_SwapWindow(sdlWindow);
		assert(glGetError() == GL_NO_ERROR);
	}

	~this() {
		if(sdlWindow) {
			SDL_DestroyWindow(sdlWindow);
			SDL_GL_DeleteContext(glContext);
			SDL_Quit();
		}
	}
}