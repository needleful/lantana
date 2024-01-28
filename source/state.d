
module state;
import runtime;

enum Event {
	None,
	Exit,
	Reload
}

struct State {
	Window window;
}