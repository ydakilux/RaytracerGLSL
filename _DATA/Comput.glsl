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

float Pow2( in float X )
{
  return X * X;
}

//------------------------------------------------------------------------------

float length2( in vec3 V )
{
  return Pow2( V.x ) + Pow2( V.y ) + Pow2( V.z );
}

//------------------------------------------------------------------------------

float Hash( in float x )
{
  return fract( sin( x ) * 43758.5453123 );
}

//------------------------------------------------------------------------------

vec4 _RandSeed;

float Random()
{
  const vec4 q = vec4(    1225,    1585,    2457,    2098 );
  const vec4 r = vec4(    1112,     367,      92,     265 );
  const vec4 a = vec4(    3423,    2646,    1707,    1999 );
  const vec4 m = vec4( 4194287, 4194277, 4194191, 4194167 );

  vec4 beta  = floor( _RandSeed / q );

  vec4 p = a * ( _RandSeed - beta * q ) - beta * r;

  _RandSeed = p + ( sign( -p ) + vec4( 1 ) ) * vec4( 0.5 ) * m;

  return fract( dot( _RandSeed / m, vec4( +1, -1, +1, -1 ) ) );
}

//------------------------------------------------------------------------------

vec2 VecToSky( in vec3 Vec )
{
  vec2 Result;

  Result.x = ( Pi - atan( -Vec.x, -Vec.z ) ) / Pi2;
  Result.y =        acos(  Vec.y           ) / Pi ;

  return Result;
}

//------------------------------------------------------------------------------

vec3 ToneMap( in vec3 Color, in float White )
{
  return clamp( Color * ( 1 + Color / White ) / ( 1 + Color ), 0, 1 );
}

//------------------------------------------------------------------------------

vec3 GammaCorrect( in vec3 Color, in float Gamma )
{
  vec3 Result;

  float G = 1 / Gamma;

  Result.r = pow( Color.r, G );
  Result.g = pow( Color.g, G );
  Result.b = pow( Color.b, G );

  return Result;
}

//------------------------------------------------------------------------------

float Fresnel( in vec3 Vec, in vec3 Nor, in float IOR )
{
  // float N = Pow2( IOR );
  // float C = dot( Vec, Nor );
  // float G = sqrt( N + Pow2( C ) - 1 );
  // float NC = N * C;
  // return ( Pow2( (  C + G ) / (  C - G ) )
  //        + Pow2( ( NC + G ) / ( NC - G ) ) ) / 2;

  float R = Pow2( ( IOR - 1 ) / ( IOR + 1 ) );
  float C = clamp( dot( Vec, Nor ), -1, 0 );
  return R + ( 1 - R ) * pow( 1 + C, 5 );
}

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【外部変数】

writeonly uniform image2D _Imager;

layout( rgba32f ) uniform image2D _Accumr;

layout( std430 ) buffer TAccumN
{
  int _AccumN;
};

layout( std430 ) buffer TBuffer
{
  mat4 _Matrix;
};

uniform sampler2D _Textur;

//############################################################################## ■

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRay

struct TRay
{
  int  Lev;
  vec4 Pos;
  vec4 Vec;
  vec3 Col;
};

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% THit

struct THit
{
  float t;
  vec4  Pos;
  vec4  Nor;
};

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【内部変数】

const int _RecL = 6;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% _Rays

TRay _Rays[ _RecL ];
int  _RaysN;

//------------------------------------------------------------------------------

void InitRays()
{
  const TRay R = TRay( 0, vec4( 0 ), vec4( 0 ), vec3( 0 ) );

  for( int I = 0; I < _RecL; I++ ) _Rays[ I ] = R;

  _RaysN = 0;
}

//------------------------------------------------------------------------------

void PushRay( in TRay Ray )
{
  _Rays[ _RaysN ] = Ray;

  _RaysN++;
}

//------------------------------------------------------------------------------

TRay PopRay()
{
  _RaysN--;

  return _Rays[ _RaysN ];
}

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【物体】

bool ObjPlane( in TRay Ray, inout THit Hit )
{
  if( Ray.Vec.y < 0 )
  {
    float t = ( Ray.Pos.y - -2 ) / -Ray.Vec.y;

    if( ( 0 < t ) && ( t < Hit.t ) )
    {
      Hit.t   = t;
      Hit.Pos = Ray.Pos + t * Ray.Vec;
      Hit.Nor = vec4( 0, 1, 0, 0 );

      return true;
    }
  }

  return false;
}

//------------------------------------------------------------------------------

bool ObjSpher( in TRay Ray, inout THit Hit )
{
  float B = dot( Ray.Pos.xyz, Ray.Vec.xyz );
  float C = length2( Ray.Pos.xyz ) - 1;

  float D = Pow2( B ) - C;

  if( D > 0 )
  {
    float t = -B - sign( C ) * sqrt( D );

    if( ( 0 < t ) && ( t < Hit.t ) )
    {
      Hit.t   = t;
      Hit.Pos = Ray.Pos + t * Ray.Vec;
      Hit.Nor = Hit.Pos;

      return true;
    }
  }

  return false;
}

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【材質】

const float _EmitShift = 0.0001;

////////////////////////////////////////////////////////////////////////////////

void MatWater( in TRay Ray, in THit Hit )
{
  float IOR;
  vec4  Nor;

  if( dot( Ray.Vec.xyz, Hit.Nor.xyz ) < 0 )
  {
    IOR = 1.333 / 1.000;
    Nor = +Hit.Nor;
  }
  else
  {
    IOR = 1.000 / 1.333;
    Nor = -Hit.Nor;
  }

  TRay R;

  R.Lev = Ray.Lev + 1;

  float F = Fresnel( Ray.Vec.xyz, Nor.xyz, IOR );

  if( Random() < F )
  {

    R.Vec = vec4( reflect( Ray.Vec.xyz, Nor.xyz ), 0 );
    R.Pos = Hit.Pos + _EmitShift * Nor;
    R.Col = Ray.Col;

    PushRay( R );
  }
  else
  {
    R.Vec = vec4( refract( Ray.Vec.xyz, Nor.xyz, 1 / IOR ), 0 );
    R.Pos = Hit.Pos - _EmitShift * Nor;
    R.Col = Ray.Col;

    PushRay( R );
  }
}

//------------------------------------------------------------------------------

void MatMirro( in TRay Ray, in THit Hit )
{
  TRay R;

  R.Lev = Ray.Lev + 1;
  R.Vec = vec4( reflect( Ray.Vec.xyz, Hit.Nor.xyz ), 0 );
  R.Pos = Hit.Pos + _EmitShift * Hit.Nor;
  R.Col = Ray.Col * vec3( 1, 1, 1 );

  PushRay( R );
}

//##############################################################################

void InitRandom()
{
  _RandSeed.x = Hash( _WorkID.x );
  _RandSeed.y = Hash( _WorkID.y );
  _RandSeed.z = Hash( _AccumN + _WorkID.x );
  _RandSeed.w = Hash( _AccumN + _WorkID.y );

  for( int I = 0; I < 4; I++ ) Random();
}

////////////////////////////////////////////////////////////////////////////////

void main()
{
  InitRandom();

  const vec4 EyePos = vec4( 0, 0, 3, 1 );

  vec4 ScrPos;
  ScrPos.x =       4 * ( _WorkID.x + 0.5 ) / _WorksN.x - 2;
  ScrPos.y = 1.5 - 3 * ( _WorkID.y + 0.5 ) / _WorksN.y    ;
  ScrPos.z = 1;
  ScrPos.w = 1;

  TRay PriRay;
  PriRay.Lev = 0;
  PriRay.Pos = _Matrix * EyePos;
  PriRay.Vec = _Matrix * normalize( ScrPos - EyePos );
  PriRay.Col = vec3( 1, 1, 1 );

  vec3 C = vec3( 0, 0, 0 );

  InitRays();

  PushRay( PriRay );

  while( _RaysN > 0 )
  {
    TRay Ray = PopRay();

    if( Ray.Lev < _RecL )
    {
      THit Hit = THit( 10000, vec4( 0 ), vec4( 0 ) );

      int Mat = 0;

      if ( ObjSpher( Ray, Hit ) ) { Mat = 1; }
      if ( ObjPlane( Ray, Hit ) ) { Mat = 2; }

      switch( Mat )
      {
        case 0: C += Ray.Col * texture( _Textur, VecToSky( Ray.Vec.xyz ) ).rgb; break;
        case 1: MatWater( Ray, Hit ); break;
        case 2: MatMirro( Ray, Hit ); break;
      }
    }
  }

  vec3 A = imageLoad( _Accumr, _WorkID.xy ).rgb;

  A += ( C - A ) / ( _AccumN + 1 );

  imageStore( _Accumr, _WorkID.xy, vec4( A, 1 ) );

  vec3 P = ToneMap( A, 100 );

  P = GammaCorrect( P, 2.2 );

  imageStore( _Imager, _WorkID.xy, vec4( P, 1 ) );
}

//############################################################################## ■
