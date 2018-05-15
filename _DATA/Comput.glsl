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

void Swap( inout uint A, inout uint B )
{
  uint C = A;  A = B;  B = C;
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

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRays

const int _RecN = 5;

struct TRays
{
  TRay Rays[ 1 << _RecN ];
  uint RaysN;
};

TRays _Rayset[ 2 ];
uint  _InRaysI = 0;
uint  _EmRaysI = 1;

//------------------------------------------------------------------------------

void AddEmRay( in TRay Ray )
{
  _Rayset[ _EmRaysI ].Rays[ _Rayset[ _EmRaysI ].RaysN ] = Ray;
  _Rayset[ _EmRaysI ].RaysN++;
}

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【物体】

bool ObjPlane( in TRay Ray, inout THit Hit )
{
  if ( Ray.Vec.y < 0 )
  {
    float t = ( Ray.Pos.y - -2 ) / -Ray.Vec.y;

    if ( ( 0 < t ) && ( t < Hit.t ) )
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

  float C = dot( Ray.Pos.xyz, Ray.Pos.xyz ) - 1;

  if ( ( B < 0 ) || ( C < 0 ) )
  {
    float D = Pow2( B ) - C;

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

void MatWater( in TRay Ray, in THit Hit )
{
  TRay R;

  const float IOR = 1.333;

  R.Vec = vec4( refract( Ray.Vec.xyz, Hit.Nor.xyz, 1 / IOR ), 0 );
  R.Pos = Hit.Pos - 0.0001 * Hit.Nor;
  R.Col = Ray.Col * vec3( 1, 1, 1 );

  AddEmRay( R );
}

//------------------------------------------------------------------------------

void MatMirro( in TRay Ray, in THit Hit )
{
  TRay R;

  R.Vec = vec4( reflect( Ray.Vec.xyz, Hit.Nor.xyz ), 0 );
  R.Pos = Hit.Pos + 0.0001 * Hit.Nor;
  R.Col = Ray.Col * vec3( 1, 1, 1 );

  AddEmRay( R );
}

//##############################################################################

void main()
{
  const vec4 EyePos = vec4( 0, 0, 3, 1 );

  vec4 ScrPos;
  ScrPos.x =       4 * ( _WorkID.x + 0.5 ) / _WorksN.x - 2;
  ScrPos.y = 1.5 - 3 * ( _WorkID.y + 0.5 ) / _WorksN.y    ;
  ScrPos.z = 1;
  ScrPos.w = 1;

  TRay PriRay;
  PriRay.Pos = _Matrix * EyePos;
  PriRay.Vec = _Matrix * normalize( ScrPos - EyePos );
  PriRay.Col = vec3( 1, 1, 1 );

  vec3 C = vec3( 0, 0, 0 );

  _Rayset[ _InRaysI ].Rays[ 0 ] = PriRay;
  _Rayset[ _InRaysI ].RaysN     = 1;

  for( int N = 0; N < _RecN; N++ )
  {
    _Rayset[ _EmRaysI ].RaysN = 0;

    for( int I = 0; I < _Rayset[ _InRaysI ].RaysN; I++ )
    {
      TRay Ray = _Rayset[ _InRaysI ].Rays[ I ];

      THit Hit;
      Hit.t   = 10000;
      Hit.Mat = 0;

      if ( ObjPlane( Ray, Hit ) ) { Hit.Mat = 1; }
      if ( ObjSpher( Ray, Hit ) ) { Hit.Mat = 2; }

      if( Hit.Mat == 0 )
      {
        C += Ray.Col * texture( _Textur, VecToSky( Ray.Vec.xyz ) ).rgb;
      }
      else
      {
        switch( Hit.Mat )
        {
          case 1: MatWater( Ray, Hit ); break;
          case 2: MatMirro( Ray, Hit ); break;
        }
      }
    }

    Swap( _InRaysI, _EmRaysI );
  }

  C = ToneMap( C, 100 );

  C = GammaCorrect( C, 2.2 );

  imageStore( _Imager, _WorkID.xy, vec4( C, 1 ) );
}

//############################################################################## ■
