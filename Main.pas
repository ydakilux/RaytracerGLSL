unit Main;

interface //#################################################################### ■

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Objects, FMX.TabControl, FMX.ScrollBox, FMX.Memo,
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
    TabControl1: TTabControl;
      TabItem1: TTabItem;
        Image1: TImage;
      TabItem2: TTabItem;
        Memo1: TMemo;
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
    _ImageX :Integer;
    _ImageY :Integer;
    _Comput :TGLComput;
    _Imager :TGLCelIma2D_TAlphaColorF;
    _Accumr :TGLCelIma2D_TAlphaColorF;
    _AccumN :TGLStoBuf<Integer>;
    _Buffer :TGLStoBuf<TSingleM4>;
    _Textur :TGLCelTex2D_TAlphaColorF;
    ///// メソッド
    procedure InitComput;
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

     _Comput.WorksX := _ImageX;
     _Comput.WorksY := _ImageY;
     _Comput.WorksZ :=       1;

     _Comput.ShaderC.Source.LoadFromFile( '..\..\_DATA\Comput.glsl' );

     with Memo1.Lines do
     begin
          Assign( _Comput.Engine.Errors );

          if Count > 0 then TabControl1.TabIndex := 1;
     end;

     _Comput.Imagers.Add( '_Imager', _Imager );
     _Comput.Imagers.Add( '_Accumr', _Accumr );
     _Comput.Buffers.Add( 'TAccumN', _AccumN );
     _Comput.Buffers.Add( 'TBuffer', _Buffer );
     _Comput.Texturs.Add( '_Textur', _Textur );
end;

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&

procedure TForm1.FormCreate(Sender: TObject);
begin
     Image1.AutoCapture := True;

     _ImageX := 800;
     _ImageY := 600;

     _Comput := TGLComput               .Create;
     _Imager := TGLCelIma2D_TAlphaColorF.Create;
     _Accumr := TGLCelIma2D_TAlphaColorF.Create;
     _AccumN := TGLStoBuf<Integer>      .Create( GL_DYNAMIC_DRAW );
     _Buffer := TGLStoBuf<TSingleM4>    .Create( GL_DYNAMIC_DRAW );
     _Textur := TGLCelTex2D_TAlphaColorF.Create;

     InitComput;

     _Imager.Grid.CellsX := _ImageX;
     _Imager.Grid.CellsY := _ImageY;

     _Accumr.Grid.CellsX := _ImageX;
     _Accumr.Grid.CellsY := _ImageY;

     _AccumN[ 0 ] := 0;

     _Textur.Imager.LoadFromFileHDR( '..\..\_DATA\Luxo-Jr_2000x1000.hdr' );
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
     _Comput.DisposeOf;
     _Imager.DisposeOf;
     _Accumr.DisposeOf;
     _AccumN.DisposeOf;
     _Buffer.DisposeOf;
     _Textur.DisposeOf;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TForm1.Timer1Timer(Sender: TObject);
begin
     _Buffer[ 0 ] := TSingleM4.RotateX( DegToRad( _MouseA.Y ) )
                   * TSingleM4.RotateY( DegToRad( _MouseA.X ) );

     _Comput.Run;

     _AccumN[ 0 ] := _AccumN[ 0 ] + 1;

     _Imager.CopyTo( Image1.Bitmap );
end;

//------------------------------------------------------------------------------

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

          _AccumN[ 0 ] := 0;
     end;
end;

procedure TForm1.Image1MouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
     Image1MouseMove( Sender, Shift, X, Y );

     _MouseS := [];
end;

end. //######################################################################### ■
