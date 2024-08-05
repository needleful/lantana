
module game.ui.simple;

import game.ui.core;

struct UI {
	nk_sdl* sdl;
	bool valid;
	this(nk_sdl* p_sdl, const(char)* name, nk_rect_t bounds, nk_flags flags) {
		sdl = p_sdl;
		valid = cast(bool) nk_begin(&sdl.ctx, name, bounds, flags);
	}

	~this() {
		nk_end(&sdl.ctx);
	}

	void grabHandle() {
		nk_sdl_handle_grab(sdl);
	}

	void endInput() {
		nk_input_end(&sdl.ctx);
	}

	void fixedRow(float height, int width, int col = 1) {
		nk_layout_row_static(&sdl.ctx, height, width, col);
	}

	void flexRow(float height, int col = 1) {
		nk_layout_row_dynamic(&sdl.ctx, height, col);
	}

	void label(const(char)* text, nk_flags flags = NK_TEXT_ALIGN_LEFT | NK_TEXT_ALIGN_MIDDLE) {
		nk_label(&sdl.ctx, text, flags);
	}

	bool button(const(char)* text) {
		return cast(bool) nk_button_label(&sdl.ctx, text);
	}

	bool option(const(char)* text, bool value) {
		return cast(bool) nk_option_label(&sdl.ctx, text, value);
	}

	T slider(T, bool modify=true)(const(char)* name, T min, ref T value, T max, T step, float inc_per_pixel) {
		static if(is(T == int) || is(T == float) || is(T == double)) {
			alias inplace_property = mixin("nk_property_"~T.stringof);
			alias read_property = mixin("nk_property"~T.stringof[0]);
		}
		else {
			static assert(false, "Invalid type for slider");
		}

		static if(modify) {
			inplace_property(&sdl.ctx, name, min, &value, max, step, inc_per_pixel);
			return value;
		}
		else {
			return read_property(&sdl.ctx, name, min, value, max, step, inc_per_pixel);
		}
	}

	Combo!T combo(T)(T value, nk_vec2_t size) {
		return Combo!T(sdl, value, size);
	}

	float width() {
		return nk_widget_width(&sdl.ctx);
	}

	float height() {
		return nk_widget_height(&sdl.ctx);
	}

	void colorPicker(ref nk_colorf color, nk_color_format format = NK_RGBA) {
		color = nk_color_picker(&sdl.ctx, color, format);
	}

	void radio(Enum)(ref Enum value, int height)
		if(is(Enum == enum) && __traits(isIntegral, Enum))
	{
		import std.meta;
		import std.traits;
		flexRow(height, EnumMembers!Enum.length);
		static foreach(i, member; EnumMembers!Enum) {{
			enum memberName = __traits(identifier, EnumMembers!Enum[i]);
			if(option(memberName, value == member)) {
				value = member;
			} 
		}}
	}

}

struct Combo(T) {
	nk_sdl* sdl;
	bool valid;
	this(nk_sdl* p_sdl, T value, nk_vec2_t size) {
		sdl = p_sdl;
		static if(is(T == nk_color)) {
			valid = cast(bool) nk_combo_begin_color(&sdl.ctx, value, size);
		}
		else static if(is(T == const(char*))) {
			valid = cast(bool) nk_combo_begin_label(&sdl.ctx, value, size);
		}
		else {
			static assert(false, "Invalid type for Combo");
		}
	}

	~this() {
		if(valid) nk_combo_end(&sdl.ctx);
	}
}