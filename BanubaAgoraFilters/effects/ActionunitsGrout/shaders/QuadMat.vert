#include <bnb/glsl.vert>
#include <bnb/decode_int1010102.glsl>
#define bnb_IDX_OFFSET 0
#ifdef BNB_VK_1
#define gl_VertexID gl_VertexIndex
#define gl_InstanceID gl_InstanceIndex
#endif


BNB_LAYOUT_LOCATION(0) BNB_IN vec3 attrib_pos;
BNB_LAYOUT_LOCATION(3) BNB_IN vec2 attrib_uv;


// out vec3 var_uvw;
BNB_OUT(0) vec2 var_uv;

void main()
{
	gl_Position = vec4(attrib_pos, 1.);

	var_uv = attrib_uv;
}
