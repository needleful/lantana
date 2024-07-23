
module lantana.core.reflection;


struct Descriptor {
	uint size;
	static Descriptor of(T)() {
		Descriptor d;
		d.size = T.sizeof;
		return d;
	}
}