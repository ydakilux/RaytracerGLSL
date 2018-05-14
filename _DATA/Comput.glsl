#version 430

#extension GL_ARB_compute_variable_group_size : enable

//layout( local_size_variable ) in;
  layout( local_size_x = 10,
          local_size_y = 10,
          local_size_z =  1 ) in;

////////////////////////////////////////////////////////////////////////////////

  const ivec3 _WorkGrupsN = ivec3( gl_NumWorkGroups );

//const ivec3 _WorkItemsN = ivec3( gl_LocalGroupSizeARB );
  const ivec3 _WorkItemsN = ivec3( gl_WorkGroupSize     );

  const ivec3 _WorksN     = _WorkGrupsN * _WorkItemsN;

  const ivec3 _WorkID     = ivec3( gl_GlobalInvocationID );

//############################################################################## ■

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%【定数】

const float Pi  = 3.141592653589793;
const float Pi2 = Pi * 2.0;
const float P2i = Pi / 2.0;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【外部変数】

layout( std430 ) buffer TBuffer
{
    mat4 _Matrix;
};

writeonly uniform image2D _Imager;

uniform sampler2D _Textur;

//############################################################################## ■

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRay

struct TRay
{
    vec4 Pos;
    vec4 Vec;
};

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THit

struct THit
{
    float t;
    vec3  Pos;
    vec3  Nor;
};

////////////////////////////////////////////////////////////////////////////////

bool HitShpere( TRay Ray, inout THit Hit )
{
    float B = dot( Ray.Pos.xyz, Ray.Vec.xyz );

    float C = dot( Ray.Pos.xyz, Ray.Pos.xyz ) - 1;

    if ( ( C > 0 ) && ( B > 0 ) ) return false;

    float D = B * B - C;

    if ( D < 0 ) return false;

    float t = -B - sqrt( D );

    if ( t < 0 ) return false;

    Hit.t   = t;
    Hit.Pos = Ray.Pos.xyz + t * Ray.Vec.xyz;
    Hit.Nor = Hit.Pos.xyz;

    return true;
}

//------------------------------------------------------------------------------

vec2 VecToSky( vec3 Vec_ )
{
    vec2 Result;

    Result.x = ( Pi - atan( -Vec_.x, -Vec_.z ) ) / Pi2;
    Result.y =        acos(  Vec_.y          )   / Pi ;

    return Result;
}

//------------------------------------------------------------------------------

vec4 ToneMap( vec4 C_, float White_ )
{
  vec4 Result;

  Result.rgb = clamp( C_.rgb * ( 1 + C_.rgb / White_ ) / ( 1 + C_.rgb ), 0, 1 );
  Result.a   = C_.a;

  return Result;
}

//------------------------------------------------------------------------------

vec4 GammaCorrect( vec4 C_, float Gamma_ )
{
  vec4 Result;

  float G = 1 / Gamma_;

  Result.r = pow( C_.r, G );
  Result.g = pow( C_.g, G );
  Result.b = pow( C_.b, G );
  Result.a =      C_.a     ;

  return Result;
}

////////////////////////////////////////////////////////////////////////////////

void main()
{
  vec4 EyePos = vec4( 0, 0, 4, 1 );

  vec4 ScreenPos;
  ScreenPos.x =       4.0 * _WorkID.x / _WorksN.x - 2.0;
  ScreenPos.y = 1.5 - 3.0 * _WorkID.y / _WorksN.y;
  ScreenPos.z = 2.0;
  ScreenPos.w = 1.0;

  TRay Ray;
  Ray.Pos = vec4( 0, 0, 2, 1 );
  Ray.Vec = normalize( ScreenPos - EyePos );

  Ray.Pos = _Matrix * Ray.Pos;
  Ray.Vec = _Matrix * Ray.Vec;

  THit Hit;
  Hit.t = 10000;

  vec4 C;

  if ( HitShpere( Ray, Hit ) )
  {
    vec3 R = reflect( Ray.Vec.xyz, Hit.Nor );

    C = texture( _Textur, VecToSky( R ) );
  }
  else
  {
    C = texture( _Textur, VecToSky( Ray.Vec.xyz ) );
  }

  C = ToneMap( C, 10 );
  C = GammaCorrect( C, 2.2 );

  imageStore( _Imager, _WorkID.xy, C );
}

//############################################################################## ■
