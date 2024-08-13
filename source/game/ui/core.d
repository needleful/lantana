
module game.ui.core;

public import nuklear;
import runtime.sdl;

// I stole this all from the SDL GL3 demo. Hope it works in OpenGL 4!
struct nk_sdl_device {
	nk_buffer cmds;
	nk_draw_null_texture tex_null;
	GLuint vbo, vao, ebo;
	GLuint prog;
	GLuint vert_shdr;
	GLuint frag_shdr;
	GLint attrib_pos;
	GLint attrib_uv;
	GLint attrib_col;
	GLint uniform_tex;
	GLint uniform_proj;
	GLuint font_tex;
}

struct nk_sdl_vertex {
	float[2] position;
	float[2] uv;
	nk_byte[4] col;
}

struct nk_sdl {
	SDL_Window *win;
	nk_sdl_device ogl;
	nk_context ctx;
	nk_font_atlas atlas;
}

void nk_sdl_device_create(nk_sdl* sdl)
{
	static const(GLchar*) vertex_shader =
		"#version 430\n" ~
		"uniform mat4 ProjMtx;\n"~
		"in vec2 Position;\n"~
		"in vec2 TexCoord;\n"~
		"in vec4 Color;\n"~
		"out vec2 Frag_UV;\n"~
		"out vec4 Frag_Color;\n"~
		"void main() {\n"~
		"   Frag_UV = TexCoord;\n"~
		"   Frag_Color = Color;\n"~
		"   gl_Position = ProjMtx * vec4(Position.xy, 0, 1);\n"~
		"}\n";
	static const(GLchar*) fragment_shader =
		"#version 430\n"~
		"precision mediump float;\n"~
		"uniform sampler2D Texture;\n"~
		"in vec2 Frag_UV;\n"~
		"in vec4 Frag_Color;\n"~
		"out vec4 Out_Color;\n"~
		"void main(){\n"~
		"   Out_Color = Frag_Color * texture(Texture, Frag_UV.st);\n"~
		"}\n";

	nk_sdl_device *dev = &sdl.ogl;
	nk_buffer_init_default(&dev.cmds);
	dev.prog = glCreateProgram();
	dev.vert_shdr = glCreateShader(GL_VERTEX_SHADER);
	dev.frag_shdr = glCreateShader(GL_FRAGMENT_SHADER);
	glShaderSource(dev.vert_shdr, 1, &vertex_shader, null);
	glShaderSource(dev.frag_shdr, 1, &fragment_shader, null);
	glCompileShader(dev.vert_shdr);
	glCompileShader(dev.frag_shdr);
	GLint status;
	glGetShaderiv(dev.vert_shdr, GL_COMPILE_STATUS, &status);
	if(status != GL_TRUE) {
		throw new Exception("Nuklear vertex shader did not compile.");
	}
	glGetShaderiv(dev.frag_shdr, GL_COMPILE_STATUS, &status);
	if(status != GL_TRUE) {
		throw new Exception("Nuklear fragment shader did not compile.");
	}
	glAttachShader(dev.prog, dev.vert_shdr);
	glAttachShader(dev.prog, dev.frag_shdr);
	glLinkProgram(dev.prog);
	glGetProgramiv(dev.prog, GL_LINK_STATUS, &status);
	if(status != GL_TRUE) {
		throw new Exception("Nuklear shaders did not link.");
	}

	dev.uniform_tex = glGetUniformLocation(dev.prog, "Texture");
	dev.uniform_proj = glGetUniformLocation(dev.prog, "ProjMtx");
	dev.attrib_pos = glGetAttribLocation(dev.prog, "Position");
	dev.attrib_uv = glGetAttribLocation(dev.prog, "TexCoord");
	dev.attrib_col = glGetAttribLocation(dev.prog, "Color");

	{
		/* buffer setup */
		GLsizei vs = nk_sdl_vertex.sizeof;
		size_t vp = nk_sdl_vertex.position.offsetof;
		size_t vt = nk_sdl_vertex.uv.offsetof;
		size_t vc = nk_sdl_vertex.col.offsetof;

		glGenBuffers(1, &dev.vbo);
		glGenBuffers(1, &dev.ebo);
		glGenVertexArrays(1, &dev.vao);

		glBindVertexArray(dev.vao);
		glBindBuffer(GL_ARRAY_BUFFER, dev.vbo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev.ebo);

		glEnableVertexAttribArray(cast(GLuint)dev.attrib_pos);
		glEnableVertexAttribArray(cast(GLuint)dev.attrib_uv);
		glEnableVertexAttribArray(cast(GLuint)dev.attrib_col);

		glVertexAttribPointer(cast(GLuint)dev.attrib_pos, 2, GL_FLOAT, GL_FALSE, vs, cast(void*)vp);
		glVertexAttribPointer(cast(GLuint)dev.attrib_uv, 2, GL_FLOAT, GL_FALSE, vs, cast(void*)vt);
		glVertexAttribPointer(cast(GLuint)dev.attrib_col, 4, GL_UNSIGNED_BYTE, GL_TRUE, vs, cast(void*)vc);
	}

	glBindTexture(GL_TEXTURE_2D, 0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
}

void
nk_sdl_device_upload_atlas(nk_sdl* sdl, const(void*)image, int width, int height)
{
	nk_sdl_device *dev = &sdl.ogl;
	glGenTextures(1, &dev.font_tex);
	glBindTexture(GL_TEXTURE_2D, dev.font_tex);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, cast(GLsizei)width, cast(GLsizei)height, 0,
				GL_RGBA, GL_UNSIGNED_BYTE, image);
}

void
nk_sdl_device_destroy(nk_sdl* sdl)
{
	nk_sdl_device *dev = &sdl.ogl;
	glDetachShader(dev.prog, dev.vert_shdr);
	glDetachShader(dev.prog, dev.frag_shdr);
	glDeleteShader(dev.vert_shdr);
	glDeleteShader(dev.frag_shdr);
	glDeleteProgram(dev.prog);
	glDeleteTextures(1, &dev.font_tex);
	glDeleteBuffers(1, &dev.vbo);
	glDeleteBuffers(1, &dev.ebo);
	nk_buffer_free(&dev.cmds);
}

void
nk_sdl_render(nk_sdl* sdl, nk_anti_aliasing AA, int max_vertex_buffer, int max_element_buffer)
{
	nk_sdl_device *dev = &sdl.ogl;
	int width, height;
	int display_width, display_height;
	
	GLfloat[4][4] ortho = [
		[2.0f, 0.0f, 0.0f, 0.0f],
		[0.0f,-2.0f, 0.0f, 0.0f],
		[0.0f, 0.0f,-1.0f, 0.0f],
		[-1.0f,1.0f, 0.0f, 1.0f],
	];
	SDL_GetWindowSize(sdl.win, &width, &height);
	SDL_GL_GetDrawableSize(sdl.win, &display_width, &display_height);
	ortho[0][0] /= cast(GLfloat)width;
	ortho[1][1] /= cast(GLfloat)height;
	auto scale = nk_vec2(
		cast(float)display_width/cast(float)width, 
		cast(float)display_height/cast(float)height);
	
	/* setup global state */
	glViewport(0,0,display_width,display_height);
	glEnable(GL_BLEND);
	glBlendEquation(GL_FUNC_ADD);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glDisable(GL_CULL_FACE);
	glDisable(GL_DEPTH_TEST);
	glEnable(GL_SCISSOR_TEST);
	glActiveTexture(GL_TEXTURE0);

	/* setup program */
	glUseProgram(dev.prog);
	glUniform1i(dev.uniform_tex, 0);
	glUniformMatrix4fv(dev.uniform_proj, 1, GL_FALSE, &ortho[0][0]);
	{
		/* convert from command queue into draw list and draw to screen */
		const nk_draw_command *cmd;
		void *vertices, elements;
		const(nk_draw_index)*offset = null;
		nk_buffer vbuf, ebuf;

		/* allocate vertex and element buffer */
		glBindVertexArray(dev.vao);
		glBindBuffer(GL_ARRAY_BUFFER, dev.vbo);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, dev.ebo);

		glBufferData(GL_ARRAY_BUFFER, max_vertex_buffer, null, GL_STREAM_DRAW);
		glBufferData(GL_ELEMENT_ARRAY_BUFFER, max_element_buffer, null, GL_STREAM_DRAW);

		/* load vertices/elements directly into vertex/element buffer */
		vertices = glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
		elements = glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);
		{
			/* fill convert configuration */
			nk_convert_config config;
			static nk_draw_vertex_layout_element[] vertex_layout = [
				{NK_VERTEX_POSITION, NK_FORMAT_FLOAT, nk_sdl_vertex.position.offsetof},
				{NK_VERTEX_TEXCOORD, NK_FORMAT_FLOAT, nk_sdl_vertex.uv.offsetof},
				{NK_VERTEX_COLOR, NK_FORMAT_R8G8B8A8, nk_sdl_vertex.col.offsetof},
				{NK_VERTEX_ATTRIBUTE_COUNT,NK_FORMAT_COUNT,0}
			];
			memset(&config, 0, config.sizeof);
			config.vertex_layout = vertex_layout.ptr;
			config.vertex_size = nk_sdl_vertex.sizeof;
			config.vertex_alignment = nk_sdl_vertex.alignof;
			config.tex_null = dev.tex_null;
			config.circle_segment_count = 22;
			config.curve_segment_count = 22;
			config.arc_segment_count = 22;
			config.global_alpha = 1.0f;
			config.shape_AA = AA;
			config.line_AA = AA;

			/* setup buffers to load vertices and elements */
			nk_buffer_init_fixed(&vbuf, vertices, cast(nk_size)max_vertex_buffer);
			nk_buffer_init_fixed(&ebuf, elements, cast(nk_size)max_element_buffer);
			nk_convert(&sdl.ctx, &dev.cmds, &vbuf, &ebuf, &config);
		}
		glUnmapBuffer(GL_ARRAY_BUFFER);
		glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);

		/* iterate over and execute each draw command */
		for(nk_draw_command* drawcmd=nk__draw_begin(&sdl.ctx, &dev.cmds);
			drawcmd; 
			drawcmd=nk__draw_next(drawcmd, &dev.cmds, &sdl.ctx)) 
		{
			if (!drawcmd.elem_count) continue;
			glBindTexture(GL_TEXTURE_2D, cast(GLuint)drawcmd.texture.id);
			glScissor(cast(GLint)(drawcmd.clip_rect.x * scale.x),
				cast(GLint)((height - cast(GLint)(drawcmd.clip_rect.y + drawcmd.clip_rect.h)) * scale.y),
				cast(GLint)(drawcmd.clip_rect.w * scale.x),
				cast(GLint)(drawcmd.clip_rect.h * scale.y));
			glDrawElements(GL_TRIANGLES, cast(GLsizei)drawcmd.elem_count, GL_UNSIGNED_SHORT, offset);
			offset += drawcmd.elem_count;
		}
		nk_clear(&sdl.ctx);
		nk_buffer_clear(&dev.cmds);
	}

	glUseProgram(0);
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	glBindVertexArray(0);
	glDisable(GL_BLEND);
	glDisable(GL_SCISSOR_TEST);
}

extern(C) void
nk_sdl_clipboard_paste(nk_handle usr, nk_text_edit *edit)
{
	const char *text = SDL_GetClipboardText();
	if (text) nk_textedit_paste(edit, text, nk_strlen(text));
	cast(void)usr;
}

extern(C) void
nk_sdl_clipboard_copy(nk_handle usr, const char *text, int len)
{
	char *str = null;
	cast(void)usr;
	if (!len) return;
	str = cast(char*)malloc(cast(size_t)len+1);
	if (!str) return;
	memcpy(str, text, cast(size_t)len);
	str[len] = '\0';
	SDL_SetClipboardText(str);
	free(str);
}

nk_context*
nk_sdl_init(nk_sdl* sdl, SDL_Window *win)
{
	sdl.win = win;
	nk_init_default(&sdl.ctx, null);
	sdl.ctx.clip.copy = &nk_sdl_clipboard_copy;
	sdl.ctx.clip.paste = &nk_sdl_clipboard_paste;
	sdl.ctx.clip.userdata = nk_handle_ptr(null);
	nk_sdl_device_create(sdl);
	return &sdl.ctx;
}

void
nk_sdl_font_stash_begin(nk_sdl* sdl, nk_font_atlas **atlas)
{
	nk_font_atlas_init_default(&sdl.atlas);
	nk_font_atlas_begin(&sdl.atlas);
	*atlas = &sdl.atlas;
}

void
nk_sdl_font_stash_end(nk_sdl* sdl)
{
	const(void)* image; int w, h;
	image = nk_font_atlas_bake(&sdl.atlas, &w, &h, NK_FONT_ATLAS_RGBA32);
	nk_sdl_device_upload_atlas(sdl, image, w, h);
	nk_font_atlas_end(&sdl.atlas, nk_handle_id(cast(int)sdl.ogl.font_tex), &sdl.ogl.tex_null);
	if (sdl.atlas.default_font)
		nk_style_set_font(&sdl.ctx, &sdl.atlas.default_font.handle);
}

void
nk_sdl_handle_grab(nk_sdl* sdl)
{
	nk_context *ctx = &sdl.ctx;
	if (ctx.input.mouse.grab) {
		SDL_SetRelativeMouseMode(SDL_TRUE);
	} else if (ctx.input.mouse.ungrab) {
		/* better support for older SDL by setting mode first; causes an extra mouse motion event */
		SDL_SetRelativeMouseMode(SDL_FALSE);
		SDL_WarpMouseInWindow(sdl.win, cast(int)ctx.input.mouse.prev.x, cast(int)ctx.input.mouse.prev.y);
	} else if (ctx.input.mouse.grabbed) {
		ctx.input.mouse.pos.x = ctx.input.mouse.prev.x;
		ctx.input.mouse.pos.y = ctx.input.mouse.prev.y;
	}
}

int
nk_sdl_handle_event(nk_sdl* sdl, SDL_Event *evt)
{
	nk_context *ctx = &sdl.ctx;

	switch(evt.type)
	{
		case SDL_KEYUP: /* KEYUP & KEYDOWN share same routine */
		case SDL_KEYDOWN:
			{
				int down = evt.type == SDL_KEYDOWN;
				const ubyte* state = SDL_GetKeyboardState(null);
				switch(evt.key.keysym.sym)
				{
					case SDLK_RSHIFT: /* RSHIFT & LSHIFT share same routine */
					case SDLK_LSHIFT:    nk_input_key(ctx, NK_KEY_SHIFT, down); break;
					case SDLK_DELETE:    nk_input_key(ctx, NK_KEY_DEL, down); break;
					case SDLK_RETURN:    nk_input_key(ctx, NK_KEY_ENTER, down); break;
					case SDLK_TAB:       nk_input_key(ctx, NK_KEY_TAB, down); break;
					case SDLK_BACKSPACE: nk_input_key(ctx, NK_KEY_BACKSPACE, down); break;
					case SDLK_HOME:      nk_input_key(ctx, NK_KEY_TEXT_START, down);
										 nk_input_key(ctx, NK_KEY_SCROLL_START, down); break;
					case SDLK_END:       nk_input_key(ctx, NK_KEY_TEXT_END, down);
										 nk_input_key(ctx, NK_KEY_SCROLL_END, down); break;
					case SDLK_PAGEDOWN:  nk_input_key(ctx, NK_KEY_SCROLL_DOWN, down); break;
					case SDLK_PAGEUP:    nk_input_key(ctx, NK_KEY_SCROLL_UP, down); break;
					case SDLK_z:         nk_input_key(ctx, NK_KEY_TEXT_UNDO, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_r:         nk_input_key(ctx, NK_KEY_TEXT_REDO, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_c:         nk_input_key(ctx, NK_KEY_COPY, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_v:         nk_input_key(ctx, NK_KEY_PASTE, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_x:         nk_input_key(ctx, NK_KEY_CUT, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_a:         nk_input_key(ctx, NK_KEY_TEXT_LINE_START, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_e:         nk_input_key(ctx, NK_KEY_TEXT_LINE_END, down && state[SDL_SCANCODE_LCTRL]); break;
					case SDLK_UP:        nk_input_key(ctx, NK_KEY_UP, down); break;
					case SDLK_DOWN:      nk_input_key(ctx, NK_KEY_DOWN, down); break;
					case SDLK_LEFT:
						if (state[SDL_SCANCODE_LCTRL])
							nk_input_key(ctx, NK_KEY_TEXT_WORD_LEFT, down);
						else nk_input_key(ctx, NK_KEY_LEFT, down);
						break;
					case SDLK_RIGHT:
						if (state[SDL_SCANCODE_LCTRL])
							nk_input_key(ctx, NK_KEY_TEXT_WORD_RIGHT, down);
						else nk_input_key(ctx, NK_KEY_RIGHT, down);
						break;
					default: break;
				}
			}
			return 1;

		case SDL_MOUSEBUTTONUP: /* MOUSEBUTTONUP & MOUSEBUTTONDOWN share same routine */
		case SDL_MOUSEBUTTONDOWN:
			{
				int down = evt.type == SDL_MOUSEBUTTONDOWN;
				const int x = evt.button.x, y = evt.button.y;
				switch(evt.button.button)
				{
					case SDL_BUTTON_LEFT:
						if (evt.button.clicks > 1)
							nk_input_button(ctx, NK_BUTTON_DOUBLE, x, y, down);
						nk_input_button(ctx, NK_BUTTON_LEFT, x, y, down); break;
					case SDL_BUTTON_MIDDLE: nk_input_button(ctx, NK_BUTTON_MIDDLE, x, y, down); break;
					case SDL_BUTTON_RIGHT:  nk_input_button(ctx, NK_BUTTON_RIGHT, x, y, down); break;
					default: break;
				}
			}
			return 1;

		case SDL_MOUSEMOTION:
			if (ctx.input.mouse.grabbed) {
				int x = cast(int)ctx.input.mouse.prev.x, y = cast(int)ctx.input.mouse.prev.y;
				nk_input_motion(ctx, x + evt.motion.xrel, y + evt.motion.yrel);
			}
			else nk_input_motion(ctx, evt.motion.x, evt.motion.y);
			return 1;

		case SDL_TEXTINPUT:
			{
				nk_glyph glyph;
				memcpy(glyph.ptr, evt.text.text.ptr, NK_UTF_SIZE);
				nk_input_glyph(ctx, glyph.ptr);
			}
			return 1;

		case SDL_MOUSEWHEEL:
			nk_input_scroll(ctx,nk_vec2(cast(float)evt.wheel.x,cast(float)evt.wheel.y));
			return 1;
		default: break;
	}
	return 0;
}


void nk_sdl_shutdown(nk_sdl* sdl)
{
	nk_font_atlas_clear(&sdl.atlas);
	nk_free(&sdl.ctx);
	nk_sdl_device_destroy(sdl);
	memset(&sdl, 0, sdl.sizeof);
}