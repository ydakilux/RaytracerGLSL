﻿unit LUX.GPU.OpenGL.Atom.Imager.D1;

interface //#################################################################### ■

uses Winapi.OpenGL, Winapi.OpenGLext,
     LUX,
     LUX.Data.Lattice.T1,
     LUX.GPU.OpenGL.Atom.Buffer.PixBuf.D1,
     LUX.GPU.OpenGL.Atom.Imager;

type //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【型】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

     //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>

     IGLImager1D = interface( IGLImager )
     ['{93701122-C0C0-4697-9E0E-C0D59EAB9706}']
     {protected}
     {public}
     end;

     //-------------------------------------------------------------------------

     TGLImager1D<_TItem_:record;
                 _TGrider_:TArray1D<_TItem_>,constructor;
                 _TIter_:TGLPixBufIter1D<_TItem_>,constructor;
                 _TGrid_:TGLPixBuf1D<_TItem_,_TIter_>,constructor> = class( TGLImager<_TItem_,_TGrider_,_TIter_,_TGrid_>, IGLImager1D )
     private
     protected
     public
       constructor Create;
       destructor Destroy; override;
       ///// メソッド
       procedure SendData; override;
       procedure SendPixBuf; override;
     end;

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLPoiIma1D<_TItem_>

     IGLPoiIma1D = interface( IGLImager1D )
     ['{4EA9561A-275A-4596-A404-6DCEBBECEA0A}']
     {protected}
     {public}
     end;

     //-------------------------------------------------------------------------

     TGLPoiIma1D<_TItem_:record> = class( TGLImager1D<_TItem_,TPoinArray1D<_TItem_>,TGLPoiPixIter1D<_TItem_>,TGLPoiPix1D<_TItem_>>, IGLPoiIma1D )
     private
     protected
     public
     end;

     //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLCelIma1D<_TItem_>

     IGLCelIma1D = interface( IGLImager1D )
     ['{8B4D30F6-68C5-4F89-B21E-6BA66CFC8BFD}']
     {protected}
     {public}
     end;

     //-------------------------------------------------------------------------

     TGLCelIma1D<_TItem_:record> = class( TGLImager1D<_TItem_,TCellArray1D<_TItem_>,TGLCelPixIter1D<_TItem_>,TGLCelPix1D<_TItem_>>, IGLCelIma1D )
     private
     protected
     public
     end;

//const //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【定数】

//var //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【変数】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

implementation //############################################################### ■

uses System.Math;

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【レコード】

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【クラス】

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

constructor TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>.Create;
begin
     inherited Create( GL_TEXTURE_1D );

end;

destructor TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>.Destroy;
begin

     inherited;
end;

/////////////////////////////////////////////////////////////////////// メソッド

procedure TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>.SendData;
begin
     Bind;
       glTexImage1D( _Kind, 0, _TexelF, _Grider.ElemsX, 0,
                               _PixelF,
                               _PixelT,
                               _Grider.Elem0P );
     Unbind;
end;

//------------------------------------------------------------------------------

procedure TGLImager1D<_TItem_,_TGrider_,_TIter_,_TGrid_>.SendPixBuf;
begin
     Bind;
       glTexImage1D( _Kind, 0, _TexelF, _Grid.ItemsX, 0,
                               _PixelF,
                               _PixelT, nil );
     Unbind;
end;

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLPoiIma1D<_TItem_>

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TGLCelIma1D<_TItem_>

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& private

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& protected

//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& public

//$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$【ルーチン】

//############################################################################## □

initialization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 初期化

finalization //$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$ 最終化

end. //######################################################################### ■