
module game.state;
import runtime.reflection;

struct GameState {
	Descriptor descriptor;
	int counter = 0;
}

GameState *gs;