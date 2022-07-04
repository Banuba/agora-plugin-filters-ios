#include <bnb/glsl.vert>
#include <bnb/decode_int1010102.glsl>
#define bnb_IDX_OFFSET 0
#ifdef BNB_VK_1
#define gl_VertexID gl_VertexIndex
#define gl_InstanceID gl_InstanceIndex
#endif


#define GLFX_TBN
#define GLFX_LIGHTING

BNB_LAYOUT_LOCATION(0) BNB_IN vec3 attrib_pos;
#ifdef GLFX_LIGHTING
#ifdef BNB_VK_1
BNB_LAYOUT_LOCATION(1) BNB_IN uint attrib_n;
#else
BNB_LAYOUT_LOCATION(1) BNB_IN vec4 attrib_n;
#endif
#ifdef GLFX_TBN
#ifdef BNB_VK_1
BNB_LAYOUT_LOCATION(2) BNB_IN uint attrib_t;
#else
BNB_LAYOUT_LOCATION(2) BNB_IN vec4 attrib_t;
#endif
#endif
#endif
BNB_LAYOUT_LOCATION(3) BNB_IN vec2 attrib_uv;
#ifndef BNB_GL_ES_1
BNB_LAYOUT_LOCATION(4) BNB_IN uvec4 attrib_bones;
#else
BNB_LAYOUT_LOCATION(4) BNB_IN vec4 attrib_bones;
#endif
#ifndef GLFX_1_BONE
BNB_LAYOUT_LOCATION(5) BNB_IN vec4 attrib_weights;
#endif
#ifdef GLFX_MALI_VERTEX_ID_ATTRIB
BNB_LAYOUT_LOCATION(6) BNB_IN uint attrib_vertex_id;
#endif



BNB_DECLARE_SAMPLER_2D(10, 11, bnb_BONES);


BNB_DECLARE_SAMPLER_2D_ARRAY(8, 9, tex_blend_shapes);

BNB_OUT(0) vec2 var_uv;
#ifdef GLFX_LIGHTING
#ifdef GLFX_TBN
BNB_OUT(1) vec3 var_t;
BNB_OUT(2) vec3 var_b;
#endif
BNB_OUT(3) vec3 var_n;
BNB_OUT(4) vec3 var_v;
#endif

mat3x4 get_bone( uint bone_idx, int y )
{
    int b = int(bone_idx)*3;
    mat3x4 m = mat3x4( 
        texelFetch(BNB_SAMPLER_2D(bnb_BONES), ivec2(b,y), 0 ),
        texelFetch(BNB_SAMPLER_2D(bnb_BONES), ivec2(b+1,y), 0 ),
        texelFetch(BNB_SAMPLER_2D(bnb_BONES), ivec2(b+2,y), 0 ) );
    return m;
}

mat3x4 get_transform()
{
    int y = int(bnb_ANIMKEY);
    mat3x4 m = get_bone( attrib_bones[0], y );
#ifndef GLFX_1_BONE
    if( attrib_weights[1] > 0. )
    {
        m = m*attrib_weights[0] + get_bone( attrib_bones[1], y )*attrib_weights[1];
        if( attrib_weights[2] > 0. )
        {
            m += get_bone( attrib_bones[2], y )*attrib_weights[2];
            if( attrib_weights[3] > 0. )
                m += get_bone( attrib_bones[3], y )*attrib_weights[3];
        }
    }
#endif
    return m;
}

mat3 shortest_arc_m3( vec3 from, vec3 to )
{
    vec3 a = cross( from, to );
    float c = dot( from, to );

    float t = 1./(1.+c);
    float tx = t*a.x;
    float ty = t*a.y;
    float tz = t*a.z;
    float txy = tx*a.y;
    float txz = tx*a.z;
    float tyz = ty*a.z;

    return mat3
    (
        c + tx*a.x, txy + a.z, txz - a.y,
        txy - a.z, c + ty*a.y, tyz + a.x,
        txz + a.y, tyz - a.x, c + tz*a.z
    );
}

void main()
{
    vec3 vpos = attrib_pos;
#ifdef GLFX_MALI_VERTEX_ID_ATTRIB
    int vertex_idx = int(attrib_vertex_id) - int(bnb_IDX_OFFSET);
#else
    int vertex_idx = gl_VertexID - int(bnb_IDX_OFFSET);
#endif
    ivec2 bs_p_uv = ivec2((vertex_idx&31)<<1,vertex_idx>>5);
#ifdef GLFX_LIGHTING
    vec3 vn = bnb_decode_int1010102(attrib_n).xyz;
    ivec2 bs_n_uv = ivec2(bs_p_uv.x+1,bs_p_uv.y);
#endif

    int au_size = 41;//textureSize(BNB_SAMPLER_2D_ARRAY(tex_blend_shapes), 0 ).z;
    for( int i = 0; i != au_size; ++i )
    {
        float bs_w = bnb_AU[i>>2][i&3];
        if( bs_w != 0. )
        {
            vec3 bs_p_delta = texelFetch(BNB_SAMPLER_2D_ARRAY(tex_blend_shapes), ivec3(bs_p_uv,i), 0 ).xyz*bs_w;
            vpos += bs_p_delta;
#ifdef GLFX_LIGHTING
            vec3 bs_n_delta = texelFetch(BNB_SAMPLER_2D_ARRAY(tex_blend_shapes), ivec3(bs_n_uv,i), 0 ).xyz*bs_w;
            vn += bs_n_delta;
#endif
        }
    }

    mat3x4 m = get_transform();
    vpos = vec4(vpos,1.)*m;


    gl_Position = bnb_MVP * vec4(vpos,1.);

    var_uv = attrib_uv;

#ifdef GLFX_LIGHTING
    vn = normalize(vn);
    var_n = mat3(bnb_MV)*(vn*mat3(m));
#ifdef GLFX_TBN
    vec3 vt = shortest_arc_m3(bnb_decode_int1010102(attrib_n).xyz,vn)*bnb_decode_int1010102(attrib_t).xyz;
    var_t = mat3(bnb_MV)*(vt*mat3(m));
    var_b = bnb_decode_int1010102(attrib_t).w*cross( var_n, var_t );
#endif
    var_v = (bnb_MV*vec4(vpos,1.)).xyz;
#endif
}