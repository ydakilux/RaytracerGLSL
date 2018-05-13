unit Main;

interface //#################################################################### ■

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects,
  Winapi.OpenGL, Winapi.OpenGLext,
  LUX, LUX.D1, LUX.D2, LUX.D3, LUX.M4, LUX.FMX.Controls,
  LUX.GPU.OpenGL,
  LUX.GPU.OpenGL.Atom.Buffer.StoBuf,
  LUX.GPU.OpenGL.Atom.Buffer.PixBuf.D1,
  LUX.GPU.OpenGL.Atom.Buffer.PixBuf.D2,
  LUX.GPU.OpenGL.Atom.Imager,
  LUX.GPU.OpenGL.Atom.Imager.D1.Preset,
  LUX.GPU.OpenGL.Atom.Imager.D2.Preset,
  LUX.GPU.OpenGL.Atom.Textur.D1.Preset,
  LUX.GPU.OpenGL.Atom.Textur.D2.Preset,
  LUX.GPU.OpenGL.Comput;

type
  TForm1 = class(TForm)
    Image1: TImage;
    Timer1: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure Timer1Timer(Sender: TObject);
  private
    { private 宣言 }
    _MouseS :TShiftState;
    _MouseP :TSingle2D;
    _MouseA :TSingle2D;
  public
    { public 宣言 }
    _ImageW :Integer;
    _ImageH :Integer;
    _Comput :TGLComput;
    _Buffer :TGLStoBuf<TSingleM4>;
    _Textur :TGLCelTex2D_TAlphaColorF;
    _Imager :TGLCelIma2D_TAlphaColorF;
    ///// メソッド
    procedure InitComput;
    procedure InitBuffer;
    procedure InitTextur;
    procedure InitImager;
    procedure Draw;
  end;

var
  Form1: TForm1;

implementation //############################################################### ■

uses System.Math;

{$R *.fmx}

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

/////////////////////////////////////////////////////////////////////// メソッド

procedure TForm1.InitComput;
begin
     _Comput.ItemsX := 10;
     _Comput.ItemsY := 10;
     _Comput.ItemsZ :=  1;

     _Comput.WorksX := _ImageW;
     _Comput.WorksY := _ImageH;
     _Comput.WorksZ :=       1;

     _Comput.ShaderC.Source.LoadFromFile( '..\..\_DATA\Comput.glsl' );

     Assert( _Comput.ShaderC.Status, _Comput.ShaderC.Errors.Text );
     Assert( _Comput.Engine .Status, _Comput.Engine .Errors.Text );

     _Comput.Buffers.Add( 'TBuffer', _Buffer );
     _Comput.Imagers.Add( '_Imager', _Imager );
     _Comput.Texturs.Add( '_Textur', _Textur );
end;

procedure TForm1.InitBuffer;
begin
     _Buffer[ 0 ] := TSingleM4.Translate( 0, 0, 0 );
end;

procedure TForm1.InitTextur;
begin
     _Textur.Imager.LoadFromFileHDR( '..\..\_DATA\Luxo-Jr_2000x1000.hdr' );
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
     _Comput.Run;

     _Imager.CopyTo( Image1.Bitmap );
end;

procedure TForm1.InitImager;
begin
     _Imager.Grid.CellsX := _ImageW;
     _Imager.Grid.CellsY := _ImageH;
end;

//------------------------------------------------------------------------------

procedure TForm1.Draw;
begin
     //_Comput.RunARB;
     _Comput.Run;

     _Imager.CopyTo( Image1.Bitmap );
end;

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

procedure TForm1.FormCreate(Sender: TObject);
begin
     Image1.AutoCapture := True;

     _Comput := TGLComput.Create;
     _Buffer := TGLStoBuf<TSingleM4>.Create( GL_STATIC_DRAW );
     _Textur := TGLCelTex2D_TAlphaColorF.Create;
     _Imager := TGLCelIma2D_TAlphaColorF.Create;

     _ImageW := 800;
     _ImageH := 600;

     InitComput;
     InitBuffer;
     InitTextur;
     InitImager;

     Draw;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     _Comput.DisposeOf;
     _Buffer.DisposeOf;
     _Textur.DisposeOf;
     _Imager.DisposeOf;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TForm1.Image1MouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
     _MouseS := Shift;
     _MouseP := TSingle2D.Create( X, Y );
end;

procedure TForm1.Image1MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
   P :TSingle2D;
begin
     if ssLeft in _MouseS then
     begin
          P := TSingle2D.Create( X, Y );

          _MouseA := _MouseA + ( P - _MouseP );

          _MouseP := P;

          _Buffer[ 0 ] := TSingleM4.RotateX( DegToRad( _MouseA.Y ) )
                        * TSingleM4.RotateY( DegToRad( _MouseA.X ) );
     end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
     Image1MouseMove( Sender, Shift, X, Y );

     _MouseS := [];
end;

end. //######################################################################### ■
