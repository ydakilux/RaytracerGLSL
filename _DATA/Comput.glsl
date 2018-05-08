#version 430

#extension GL_ARB_compute_variable_group_size : enable

//layout( local_size_variable ) in;
layout( local_size_x = 10,
        local_size_y = 10,
        local_size_z =  1 ) in;

////////////////////////////////////////////////////////////////////////////////

const ivec3 _WorkGrupsN = ivec3( gl_NumWorkGroups );

//const ivec3 _WorkItemsN = ivec3( gl_LocalGroupSizeARB );
const ivec3 _WorkItemsN = ivec3( gl_WorkGroupSize );

const ivec3 _WorksN = _WorkGrupsN * _WorkItemsN;

//############################################################################## ■

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【外部変数】

layout( std430 ) buffer TBuffer
{
    mat4 _Matrix;
};

writeonly uniform image2D _Imager;

uniform sampler1D _Textur;

//############################################################################## ■

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRay

struct TRay
{
    vec3 Pos;
    vec3 Vec;
};

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THit

struct THit
{
    float t;
    vec3  Pos;
};

////////////////////////////////////////////////////////////////////////////////

bool HitShpere( TRay Ray, inout THit Hit )
{
    float B = dot( Ray.Pos, Ray.Vec );

    float C = dot( Ray.Pos, Ray.Pos ) - 1;

    if ( C > 0.0f && B > 0.0f ) return false;

    float D = B * B - C;

    if ( D < 0.0 ) return false;

    float t = -B - sqrt( D );

    if ( t < 0.0 ) return false;

    Hit.t   = t;
    Hit.Pos = Ray.Pos + t * Ray.Vec;

    return true;
}

////////////////////////////////////////////////////////////////////////////////

void main()
{
  ivec2 I = ivec2( gl_GlobalInvocationID.xy );

  vec3 EyePos = vec3( 0, 0, 2 );

  vec3 ScreenPos;
  ScreenPos.x = 2.0 * I.x / _WorksN.x - 1.0;
  ScreenPos.y = 1.0 - 2.0 * I.y / _WorksN.y;
  ScreenPos.z = 1.0;

  TRay Ray;
  Ray.Pos = vec3( 0, 0, 2 );
  Ray.Vec = normalize( ScreenPos - EyePos );

  THit Hit;
  Hit.t = 10000;

  vec4 C;
  if ( HitShpere( Ray, Hit ) )
  {
    C = vec4( 1, 0, 0, 1 );
  }
  else
  {
    C = vec4( 0, 0, 0, 1 );
  }

  imageStore( _Imager, I, C );
}

//############################################################################## ■
