
module state;

enum Event {
	None,
	Exit,
	Reload
}

struct State {
	string name;
	Event event;
}