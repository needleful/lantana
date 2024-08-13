
module runtime;
public import runtime.events;
public import runtime.memory;
public import runtime.sdl;

struct RuntimeState {
	Window window;
	BaseRegion memory;
}