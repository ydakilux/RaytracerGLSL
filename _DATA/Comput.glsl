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

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【定数】

const float Pi  = 3.141592653589793;
const float Pi2 = Pi * 2.0;
const float P2i = Pi / 2.0;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

vec2 VecToSky( vec3 Vec_ )
{
    vec2 Result;

    Result.x = ( Pi - atan( -Vec_.x, -Vec_.z ) ) / Pi2;
    Result.y =        acos(  Vec_.y          )   / Pi ;

    return Result;
}

//------------------------------------------------------------------------------

vec3 ToneMap( vec3 C_, float White_ )
{
  vec3 Result;

  Result = clamp( C_ * ( 1 + C_ / White_ ) / ( 1 + C_ ), 0, 1 );

  return Result;
}

//------------------------------------------------------------------------------

vec3 GammaCorrect( vec3 C_, float Gamma_ )
{
  vec3 Result;

  float G = 1 / Gamma_;

  Result.r = pow( C_.r, G );
  Result.g = pow( C_.g, G );
  Result.b = pow( C_.b, G );

  return Result;
}

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
    vec3 Col;
};

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THit

struct THit
{
    float t;
    int   Mat;
    vec4  Pos;
    vec4  Nor;
};

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【物体】

bool ObjPlane( TRay Ray, inout THit Hit )
{
  if ( Ray.Vec.y < 0 )
  {
    float t = ( Ray.Pos.y - -2 ) / -Ray.Vec.y;

    if ( ( 0 < t ) && ( t < Hit.t ) )
    {
      Hit.t   = t;
      Hit.Pos = Ray.Pos + t * Ray.Vec;
      Hit.Nor = vec4( 0, 1, 0, 1 );

      return true;
    }
  }
  return false;
}

//------------------------------------------------------------------------------

bool ObjSpher( TRay Ray, inout THit Hit )
{
  float B = dot( Ray.Pos.xyz, Ray.Vec.xyz );

  float C = dot( Ray.Pos.xyz, Ray.Pos.xyz ) - 1;

  if ( ( B < 0 ) || ( C < 0 ) )
  {
    float D = B * B - C;

    if ( D > 0 )
    {
      float t = -B - sqrt( D );

      if ( ( 0 < t ) && ( t < Hit.t ) )
      {
        Hit.t   = t;
        Hit.Pos = Ray.Pos + t * Ray.Vec;
        Hit.Nor = Hit.Pos;

        return true;
      }
    }
  }
  return false;
}

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【材質】

void MatWater( in THit Hit, inout TRay Ray )
{
  Ray.Vec.xyz = refract( Ray.Vec.xyz, Hit.Nor.xyz, 1 / 1.333 );
  Ray.Col     = Ray.Col * vec3( 1, 1, 1 );
}

void MatMirro( in THit Hit, inout TRay Ray )
{
  Ray.Vec.xyz = reflect( Ray.Vec.xyz, Hit.Nor.xyz );
  Ray.Col     = Ray.Col * vec3( 1, 1, 1 );
}

//##############################################################################

void main()
{
  vec4 EyePos = vec4( 0, 0, 3, 1 );

  vec4 ScrPos;
  ScrPos.x =       4.0 * _WorkID.x / _WorksN.x - 2.0;
  ScrPos.y = 1.5 - 3.0 * _WorkID.y / _WorksN.y;
  ScrPos.z = 1.0;
  ScrPos.w = 1.0;

  TRay Ray;
  Ray.Pos = _Matrix * EyePos;
  Ray.Vec = _Matrix * normalize( ScrPos - EyePos );
  Ray.Col = vec3( 1, 1, 1 );

  THit Hit;

  for ( int I = 0; I < 5; I++ )
  {
    Hit.t   = 10000;
    Hit.Mat = 0;

    if ( ObjPlane( Ray, Hit ) ) { Hit.Mat = 1; }
    if ( ObjSpher( Ray, Hit ) ) { Hit.Mat = 2; }

    if ( Hit.Mat == 0 ) break;

    switch ( Hit.Mat )
    {
      case 1: MatWater( Hit, Ray ); break;
      case 2: MatMirro( Hit, Ray ); break;
    }

    Ray.Pos = Hit.Pos + 0.0001 * Ray.Vec;
  }

  vec3 C = Ray.Col * texture( _Textur, VecToSky( Ray.Vec.xyz ) ).rgb;

  C = ToneMap( C, 10 );

  C = GammaCorrect( C, 2.2 );

  imageStore( _Imager, _WorkID.xy, vec4( C, 1 ) );
}

//############################################################################## ■
