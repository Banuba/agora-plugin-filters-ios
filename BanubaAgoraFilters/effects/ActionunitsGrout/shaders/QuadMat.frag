#include <bnb/glsl.frag>


// in vec3 var_uvw;
BNB_IN(0) vec2 var_uv;


// uniform sampler2DArray animation;

BNB_DECLARE_SAMPLER_2D(0, 1, meshTexture);
void main()
{
	bnb_FragColor = BNB_TEXTURE_2D(BNB_SAMPLER_2D(meshTexture), var_uv);
}
