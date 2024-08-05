
#define NK_INCLUDE_FIXED_TYPES
#define NK_INCLUDE_STANDARD_IO
#define NK_INCLUDE_DEFAULT_ALLOCATOR
#define NK_INCLUDE_VERTEX_BUFFER_OUTPUT
#define NK_INCLUDE_FONT_BAKING
#define NK_INCLUDE_DEFAULT_FONT
#define NK_IMPLEMENTATION
#define NK_SDL_GL3_IMPLEMENTATION
#include "nuklear/nuklear.h"

// D doesn't support functions and types with the same name.
typedef struct nk_color nk_color_t;
typedef struct nk_colorf nk_colorf_t;
typedef struct nk_cursor nk_cursor_t;
typedef struct nk_image nk_image_t;
typedef struct nk_rect nk_rect_t;
typedef struct nk_recti nk_recti_t;
typedef struct nk_nine_slice nk_nine_slice_t;
typedef struct nk_scroll nk_scroll_t;
typedef struct nk_vec2 nk_vec2_t;
typedef struct nk_vec2i nk_vec2i_t;