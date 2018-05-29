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

uint _SeedRandLCG32;

void InitRandLCG32( uint Seed )
{
  _SeedRandLCG32 = Seed;
}

void RandLCG32( out uint Rand )
{
  const uint A = 1664525;
  const uint C = 1013904223;

  _SeedRandLCG32 = A * _SeedRandLCG32 + C;

  Rand = _SeedRandLCG32;
}

//------------------------------------------------------------------------------

uvec4 _SeedRandXOR128;

void InitRandXOR128()
{
  RandLCG32( _SeedRandXOR128.x );
  RandLCG32( _SeedRandXOR128.y );
  RandLCG32( _SeedRandXOR128.z );
  RandLCG32( _SeedRandXOR128.w );
}

void RandXOR128( out uint Rand )
{
  uint T = _SeedRandXOR128.x ^ ( _SeedRandXOR128.x << 11 );

  _SeedRandXOR128.x = _SeedRandXOR128.y;
  _SeedRandXOR128.y = _SeedRandXOR128.z;
  _SeedRandXOR128.z = _SeedRandXOR128.w;

  _SeedRandXOR128.w = ( _SeedRandXOR128.w ^ ( _SeedRandXOR128.w >> 19 ) )
                    ^ (                 T ^ (                 T >>  8 ) );

  Rand = _SeedRandXOR128.w;
}

float RandXOR128()
{
  uint Result;

  RandXOR128( Result );

  return float( Result ) / 4294967296.0;
}

//------------------------------------------------------------------------------

vec2 RandCirc()
{
  vec2 Result;

  float T = Pi2 * RandXOR128();
  float R = sqrt( RandXOR128() );

  Result.x = R * cos( T );
  Result.y = R * sin( T );

  return Result;
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
  vec3 Emi;
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
  const TRay R = TRay( 0, vec4( 0 ), vec4( 0 ), vec3( 0 ), vec3( 0 ) );

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
    float t = ( Ray.Pos.y - -1.001 ) / -Ray.Vec.y;

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

void MatSkyer( inout TRay Ray, in THit Hit )
{
  Ray.Emi = texture( _Textur, VecToSky( Ray.Vec.xyz ) ).rgb;
}

//------------------------------------------------------------------------------

void MatWater( inout TRay Ray, in THit Hit )
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

  R.Vec = vec4( reflect( Ray.Vec.xyz, Nor.xyz ), 0 );
  R.Pos = Hit.Pos + _EmitShift * Nor;
  R.Col = Ray.Col * F;

  PushRay( R );

  R.Vec = vec4( refract( Ray.Vec.xyz, Nor.xyz, 1 / IOR ), 0 );
  R.Pos = Hit.Pos - _EmitShift * Nor;
  R.Col = Ray.Col * ( 1 - F );

  PushRay( R );

  Ray.Emi = vec3( 0, 0, 0 );
}

//------------------------------------------------------------------------------

void MatMirro( inout TRay Ray, in THit Hit )
{
  TRay R;

  R.Lev = Ray.Lev + 1;
  R.Vec = vec4( reflect( Ray.Vec.xyz, Hit.Nor.xyz ), 0 );
  R.Pos = Hit.Pos + _EmitShift * Hit.Nor;
  R.Col = Ray.Col;

  PushRay( R );

  Ray.Emi = vec3( 0, 0, 0 );
}

//------------------------------------------------------------------------------

void MatDiffu( inout TRay Ray, in THit Hit )
{
  TRay R;

  R.Lev = Ray.Lev + 1;

  R.Vec.y = RandXOR128();

  float d = sqrt( 1 - Pow2( R.Vec.y ) );
  float v = RandXOR128();

  R.Vec.x = d * cos( Pi2 * v );
  R.Vec.z = d * sin( Pi2 * v );

  R.Pos = Hit.Pos + _EmitShift * Hit.Nor;
  R.Col = Ray.Col;

  PushRay( R );

  Ray.Emi = vec3( 0, 0, 0 );
}

//##############################################################################

void main()
{
  InitRandLCG32( ( _AccumN * _WorksN.y + _WorkID.y ) * _WorksN.x + _WorkID.x );
  InitRandXOR128();

  vec4 EyePos = vec4( 0, 0, 3, 1 );

  EyePos.xy = EyePos.x + 0.1 * RandCirc();

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
        case 0: MatSkyer( Ray, Hit ); break;
        case 1: MatWater( Ray, Hit ); break;
        case 2: MatMirro( Ray, Hit ); break;
        case 3: MatDiffu( Ray, Hit ); break;
      }

      C += Ray.Col * Ray.Emi;
    }
  }

  vec3 A = imageLoad( _Accumr, _WorkID.xy ).rgb;

  A += ( C - A ) / ( _AccumN + 1 );

  imageStore( _Accumr, _WorkID.xy, vec4( A, 1 ) );

  vec3 P = ToneMap( A, 100 );

  P = GammaCorrect( P, 2.2 );

  imageStore( _Imager, _WorkID.xy, vec4( P, 1 ) );

  barrier();
}

//############################################################################## ■
