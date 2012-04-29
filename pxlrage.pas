  unit pxlrage;

(* ############################################################################
   # Author:  Jon Lennart Aasenden                                            #
   # Company: Jolead EM                                                       #
   # License: Copyright Jon Lennart Aasenden, all rights reserved under the   #
   #          international software apartment ownership act                  #
   ############################################################################


 /$$$$$$$  /$$                     /$$ /$$$$$$$
 | $$__  $$|__/                    | $$| $$__  $$
 | $$  \ $$ /$$ /$$   /$$  /$$$$$$ | $$| $$  \ $$  /$$$$$$   /$$$$$$   /$$$$$$
 | $$$$$$$/| $$|  $$ /$$/ /$$__  $$| $$| $$$$$$$/ |____  $$ /$$__  $$ /$$__  $$
 | $$____/ | $$ \  $$$$/ | $$$$$$$$| $$| $$__  $$  /$$$$$$$| $$  \ $$| $$$$$$$$
 | $$      | $$   gt;$$  $$ | $$_____/| $$| $$  \ $$ /$$__  $$| $$  | $$| $$__/
 | $$      | $$ /$$/\  $$|  $$$$$$$| $$| $$  | $$|  $$$$$$$|  $$$$$$$|  $$$$$$$
 |__/      |__/|__/  \__/ \_______/|__/|__/  |__/ \_______/ \____  $$ \_______/
                                                            /$$  \ $$
                                                           |  $$$$$$/
                                                            \______/

About
=====
PXR is a slim, easy to use and innovative graphics library that
represents a foundation for further, more advanced libraries.
As such SL does not implement everything under the sun, but
aims to provide a rock-solid basis that can be easily extended.
By default the unit implements a RAW surface, which is basically
a surface held in RAM without any device context. It also
provides a Windows DIB implementation that does have a context
and can thus be used with blitting and Delphi canvas operations.

PXR is not about the latest cool feature. It is about providing a platform
independent foundation, assemly free, that other more advanced libraries can
be based.

Features
========
  - 8, 15, 16, 24 and 32 bit pixelbuffers
  - Fast native blitter between pixel formats (e.g copy from 32bpp -> 8bpp)
  - Palette handling
  - Clipping
  - Basic primitives (circle, ellipse, rectangle)
  - Fill mechanism
  - Alpha blending
  - Transparency
  - DIB implementation
  - UNI implementation

DIB vs. UNI
===========
A dib (device independent bitmap) allocated un-paged memory to hold the image.
The current dib implementation is windows only (although iOS and OSX have
similar calls).

A "uni surface" is allocated from normal memory (using allocmem). This is
perfect for service applications where security does not allow you to allocate
a device context or window handle.

Dependencies
============
Pixelrage depends on some memory functions in ByteRage:
http://code.google.com/p/byterage/source/browse/trunk/brage.pas


*)

  {$DEFINE PXR_USE_DELPHI}
  {$DEFINE PXR_USE_WINDOWS}
  {.$DEFINE PXR_USE_MAC}
  {.$DEFINE PXR_USE_FREEPASCAL}
  {.$DEFINE PXR_USE_TESTING}

  interface

  uses
  {$IFDEF MSWINDOWS}
  windows,
  {$ENDIF}
  sysutils, classes, math,  brage,
  graphics;

  Type

  (* Exceptions *)
  EPXRSurfaceCustom  = Class(Exception);
  EPXRPalette        = Class(Exception);
  EPXRColor          = Class(Exception);
  EPXRRect           = Class(Exception);

  (* Forward declarations *)
  TPXRRect             = Class;
  TPXRColorCustom      = Class;
  TPXRPaletteColor     = Class;
  TPXRPaletteNetScape  = Class;
  TPXRSurfaceCustom    = Class;
  TPXRSurfaceUNI       = Class;
  TPXRSurfaceDIB       = Class;

  (* Custom types *)
  TPXRRectExposure  = (esNone,esPartly,esCompletely);
  TPXRPointArray    = Array of TPoint;
  TPXRColorArray    = Array of TColor;
  TRGBQuadArray     = Packed Array[0..255] of TRGBQuad;
  PRGBQuadArray     = ^TRGBQuadArray;
  TPXRColorPercent  = 0..100;
  TPXRRampType      = (rtRampUp,rtRampDown);
  TPXRDrawMode      = (dmCopy,dmBlend);
  TPXRPenStyle      = (stOutline,stSolid);

  TPXRBlitterProc          = procedure of Object;
  TPXRReaderProc           = Procedure (Const Col,Row:Integer;
                            var outData) of Object;
  TPXRWriterProc           = Procedure (Const Col,Row:Integer;
                            Const inData) of Object;
  TPXRFillRegionMethod     = Procedure (Const Region:TRect;
                            Const inData) of Object;
  TPXRDrawEllipseMethod    = procedure (const Domain:TRect) of Object;
  TPXRDrawPolygonMethod    = procedure (Const Domain:TPXRPointArray) of Object;

  TPXRPixelCopyProc        = Procedure (const thispixel;var thatpixel) of Object;

  TPXRPixelDecoderProc     = Procedure(const ThisPixel;var R,G,B:Byte) of Object;
  TPXRPixelEncoderProc     = procedure(Const R,G,B:Byte;var ThatPixel) of Object;


  (* Event method types *)
  TPXREventDrawModeAltered = Procedure (sender:TObject;
    const aOldValue:TPXRDrawMode;
    const aNewValue:TPXRDrawMode) of Object;

  TPXREventPenStyleAltered = Procedure (sender:TObject;
    Const aOldValue:TPXRPenStyle;
    Const aNewValue:TPXRPenStyle) of Object;

  TPXREventTransparencyAltered = Procedure (Sender:TObject;
    const aNewValue:Boolean) of Object;

  TPXREventPenColorAltered = procedure (sender:TObject;
    const aOldValue:TColor;
    const aNewValue:TColor) of Object;

  TPXREventTransparentColorAltered = procedure (sender:TObject;
    const aOldValue:TColor;
    const aNewValue:TColor) of Object;

  TPXRRect = Class(TObject)
  Private
    FRect:      TRect;
    FOnAltered: TNotifyEvent;
    Function    GetLeft:Integer;
    Function    GetRight:Integer;
    Function    GetTop:Integer;
    Function    GetBottom:Integer;
    Function    GetWidth:Integer;
    Function    getHeight:Integer;
  Public
    class function  HeightOf(const Domain:TRect):Integer;
    class function  WidthOf(Const Domain:TRect):Integer;
    class procedure Realize(var Domain:TRect);
    class function  Intersect(const Primary,Secondary:TRect;
                    var Intersection:TRect):Boolean;
    class procedure ClipTo(var Child:TRect;Const Domain:TRect);
    class function  IsValid(Const Domain:TRect):Boolean;
    class function  IsVisible(Const Child,Domain:TRect):TPXRRectExposure;

    class function  IsWithin(Const Left,Top:Integer;
                    Const Domain:TRect):Boolean;overload;
    class function  IsWithin(Const Child:TPoint;
                    Const Domain:TRect):Boolean;overload;
    class function  IsWithin(Const Child:TRect;
                    Const Domain:TRect):Boolean;overload;

    class function  MakeAbs(const aLeft,aTop,aRight,aBottom:Integer):TRect;
    class function  Make(const aLeft,aTop,aWidth,aHeight:Integer):TRect;

    class function  toString(const Domain:TRect;
          Const Full:Boolean=True):String;
    class function  toPoints(const Domain:TRect):TPXRPointArray;

    function  Contains(Const Child:TRect):Boolean;overload;
    Function  Contains(Const Left,Top:Integer):Boolean;overload;
    Function  Contains(Const Child:TPoint):Boolean;overload;

    class function NullRect:TRect;

    Property  Left:Integer read getLeft;
    Property  Top:Integer read GetTop;
    Property  Right:Integer read GetRight;
    Property  Bottom:Integer read GetBottom;
    Property  Width:Integer read GetWidth;
    Property  Height:Integer read Getheight;
    Property  Value:TRect read FRect;

    Procedure SetRect(aLeft,aTop,aRight,aBottom:Integer);overload;
    Procedure SetRect(Domain:TRect);overload;
    procedure setRect(aWidth,aHeight:Integer);overload;

    Procedure Clip(var Value:TRect);
    Function  ContainsRow(Const Row:Integer):Boolean;
    Function  ContainsColumn(Const Col:Integer):Boolean;

    Procedure Clear;
    Function  Empty:Boolean;

    Class Function  Compare(Const aFirst,aSecond:TRect):Boolean;

    Property    OnRectAltered:TNotifyEvent
                read FOnAltered write FOnAltered;

    Constructor Create;virtual;
  End;


  TPXRColorPresets = Class(TObject)
  Private
    FParent:    TPXRColorCustom;
  Public
    Procedure   White;
    procedure   Black;
    Procedure   Red;
    Procedure   Green;
    Procedure   Blue;
    Procedure   Cyan;
    Procedure   Magenta;
    Procedure   Indigo;

    Procedure   LimeGreen;
    Procedure   Pink;
    Procedure   Tomato;
    Procedure   Orange;
    Procedure   Violet;
    Procedure   Gold;
    procedure   Khaki;
    Constructor Create(AOwner:TPXRColorCustom);reintroduce;
  End;


  (* The color class *)
  TPXRColorCustom = Class(TPersistent)
  Private
    FRed:       Byte;
    FGreen:     Byte;
    FBlue:      Byte;
    FColorRef:  TColor;
    FOnChange:  TNotifyEvent;
    FBusy:      Boolean;
    FPresets:   TPXRColorPresets;
  Protected
    Procedure   SetRed(Const Value:Byte);
    Procedure   SetGreen(Const Value:Byte);
    procedure   SetBlue(Const Value:Byte);
    Procedure   SetColorRef(Const Value:TColor);
    Procedure   TripletsChanged;virtual;
  Protected
    procedure   AssignTo(Dest:TPersistent);override;
  Public
    Property    Red:Byte read FRed write SetRed;
    Property    Green:Byte read FGreen write SetGreen;
    property    Blue:Byte read FBlue write SetBlue;
    Property    Presets:TPXRColorPresets read Fpresets;

    Procedure   SetRGB(aRed,aGreen,aBlue:Byte);

    Procedure   toRGB15(var buffer);
    Procedure   toRGB16(var buffer);
    Procedure   toRGB24(var buffer);
    Procedure   toRGB32(var buffer);

    Procedure   fromRGB15(Const buffer);
    Procedure   fromRGB16(Const buffer);
    Procedure   fromRGB24(Const buffer);
    Procedure   fromRGB32(Const buffer);

    Procedure   Darker(Const Percent:TPXRColorPercent);
    Procedure   Brighter(Const Percent:TPXRColorPercent);

    Procedure   BlendFrom(Const Value:TColor;Const Factor:Byte);
    Function    BlendTo(Const Value:TColor;Const Factor:Byte):TColor;

    Procedure   Balance;overload;
    Procedure   Invert;overload;
    Function    Luminance:Integer;overload;
    Procedure   SetHSV(const H,S,V:Integer);
    Procedure   GetHSV(var H,S,V:Integer);
    Function    toHTML:String;

    {$IFDEF MSWINDOWS}
    Class function CheckSysColor(Const Value:TColor):Boolean;
    {$ENDIF}

    Class Function  Blend(Const First,Second:TColor;
                    Const Factor:TPXRColorPercent):TColor;

    Class Function  Encode(Const R,G,B:Byte):TColor;
    Class procedure Decode(Value:TColor;Var Red,Green,Blue:Byte);

    Class Procedure ColorTo15(Const Color:TColor;var Buffer);
    Class Procedure ColorTo16(Const Color:TColor;var Buffer);
    Class Procedure ColorTo24(Const Color:TColor;var Buffer);
    Class Procedure ColorTo32(Const Color:TColor;var Buffer);

    Class Function  ColorFrom15(Const Buffer):TColor;
    Class Function  ColorFrom16(Const Buffer):TColor;
    Class Function  ColorFrom24(Const Buffer):TColor;
    Class Function  ColorFrom32(Const Buffer):TColor;

    Class Procedure RGBFrom15(Const buffer;var R,G,B:Byte);
    Class procedure RGBFrom16(Const buffer;var R,G,B:Byte);
    Class Procedure RGBFrom24(Const buffer;var R,G,B:Byte);
    Class procedure RGBFrom32(Const buffer;var R,G,B:Byte);

    Class Procedure RGBTo15(var buffer;Const R,G,B:Byte);
    Class procedure RGBTo16(var buffer;Const R,G,B:Byte);
    Class Procedure RGBTo24(var buffer;Const R,G,B:Byte);
    Class procedure RGBTo32(var buffer;Const R,G,B:Byte);

    class procedure Blend15(const first;const second;
                    Const Alpha:Byte;var target);
    class procedure Blend16(const first;const second;
                    Const Alpha:Byte;var target);
    class procedure Blend24(const first;const second;
                    Const Alpha:Byte;var target);
    class procedure Blend32(const first;const second;
                    Const Alpha:Byte;var target);

    Class Function  Invert(Const Value:TColor):TColor;overload;
    Class Function  Luminance(Const Value:TColor):Integer;overload;
    Class Function  Balance(Const Value:TColor):TColor;overload;

    class function  Ramp(Const Value:TColor;
                    aCount:Byte;Style:TPXRRampType):TPXRColorArray;

    Constructor Create;virtual;
    Destructor  Destroy;Override;
    Procedure AfterConstruction;Override;
  Published
    Property  OnColorChanged:TNotifyEvent
              read FOnChange write FOnChange;
    Property  ColorRef:TColor read FColorRef write SetColorRef;
  End;


  TPXRPaletteCustom = Class(TPersistent)
  Protected
    Function  GetByteSize:Integer;virtual;
    Procedure GetItemQuad(Index:Integer;Var Data);virtual;abstract;
    Function  GetCount:Integer;virtual;abstract;
    Function  GetItem(index:Integer):TColor;virtual;abstract;
    Procedure SetItem(Index:Integer;Value:TColor);virtual;abstract;
    Function  GetReadOnly:Boolean;virtual;abstract;
  Protected
    procedure AssignTo(Dest: TPersistent);Override;
  Public
    Property  ReadOnly:Boolean read GetReadOnly;
    Property  Items[index:Integer]:TColor
              read GetItem write SetItem;
    Property  Count:Integer read GetCount;
    Property  Size:Integer read GetByteSize;

    Procedure ExportQuadArray(Const Target);
    Procedure ExportRGB(Const index:Integer;var R,G,B:Byte);virtual;
    function  ExportColorObj(Const index:Byte):TPXRPaletteColor;

    Function  Match(r,g,b:Byte):Integer;overload;dynamic;abstract;
    Function  Match(Value:TColor):Integer;overload;dynamic;
  End;

  TPXRPaletteNetscape = Class(TPXRPaletteCustom)
  Private
    FQuads:     TRGBQuadArray;
  Protected
    Function    GetReadOnly:Boolean;override;
    Procedure   GetItemQuad(Index:Integer;Var Data);override;
    Function    GetCount:Integer;override;
    Function    GetItem(index:Integer):TColor;override;
    Procedure   SetItem(Index:Integer;Value:TColor);override;
  Public
    Procedure   ExportRGB(Const index:Integer;var R,G,B:Byte);override;
    Function    Match(r,g,b:Byte):Integer;override;
    Constructor Create;virtual;
  End;

  TPXRPaletteColor = Class(TPXRColorCustom)
  public
    Procedure toRGB08(Const Palette:TPXRPaletteCustom;var buffer);virtual;
  Public
    class Function  ColorFrom08(Const Palette:TPXRPaletteCustom;
                    Const Buffer):TColor;virtual;

    Class Procedure ColorTo08(Const Color:TColor;
                    Const Palette:TPXRPaletteCustom;var Buffer);virtual;

    Class Procedure RGBFrom08(Const Palette:TPXRPaletteCustom;
                    Const buffer;var R,G,B:Byte);

    class procedure Blend08(Const Palette:TPXRPaletteCustom;
                    const first;const second;
                    Const Alpha:Byte;var target);
  End;

  TPXRSurfaceCustom = Class(TPersistent)
  Private
    FWidth:       Integer;
    FHeight:      Integer;
    FFormat:      TPixelFormat;
    FBitsPP:      Integer;
    FBytesPP:     Integer;
    FPitch:       Integer;
    FDataSize:    Integer;
    FColor:       TColor;
    FColorRaw:    Longword;
    FBounds:      TRect;

    FClipRect:    TRect;
    FClipObj:     TPXRRect;

    FPenColor:    TPXRPaletteColor;
    FPenAlpha:    Byte;
    FTransparent: Boolean;
    FTransColor:  TColor;
    FTransRaw:    Longword;
    FDrawMode:    TPXRDrawMode;
    FPenStyle:    TPXRPenStyle;
    FPalette:     TPXRPaletteCustom;
    FCursor:      TPoint;

    (* blitting *)
    FCopyTrans:     Boolean;
    FCopyKey:       Longword;
    FCopySrc:       PByte;
    FCopyDst:       PByte;
    FCopyPal:       TPXRPaletteCustom;
    FCopyCnt:       Integer;
    FCopysrcRect:   TRect;
    FCopydstRect:   TRect;
    FCopyDecoder:   TPXRPixelDecoderProc;
    FCopyEncoder:   TPXRPixelEncoderProc;

    FCopyLPC:       TPXRBlitterProc;

  Private
    (* Event declarations *)
    FOnPenStyleAltered:         TPXREventPenStyleAltered;
    FOnDrawModeAltered:         TPXREventDrawModeAltered;
    FOnPenColorAltered:         TPXREventPenColorAltered;
    FOnTransparencyAltered:     TPXREventTransparencyAltered;
    FOnTransparentColorAltered: TPXREventTransparentColorAltered;
  Private
    (* To speed things up we use lookup tables for functions that will
       be called many times during the use of a surface. For instance,
       instead of checking the pixelformat for every write - we test it
       once and assign the correct writing procedure to a variable.
       That way the surface always knows the fastest way to draw a pixel. *)
    FReadLUT:     TPXRReaderProc;
    FWriteLUT:    TPXRWriterProc;
    FFillRectLUT: TPXRFillRegionMethod;

    FReadLUTEX:     Array[pf8bit..pf32bit] of TPXRReaderProc;
    FWriteLUTEX:    Array[pf8bit..pf32bit,dmCopy..dmBlend] of TPXRWriterProc;
    FEllipseLUTEX:  Array[stOutline..stSolid] of TPXRDrawEllipseMethod;
    FFillRectLUTEX: Array[pf8bit..pf32bit,dmCopy..dmBlend] of TPXRFillRegionMethod;
    FBlitterLUT:    Array[pf8Bit..pf32Bit,pf8Bit..pf32Bit] of TPXRBlitterProc;
    FPXTraLUT:      Array[pf8Bit..pf32Bit,pf8Bit..pf32Bit] of TPXRPixelCopyProc;

    FDecoderLUT:    Array[pf8Bit..pf32Bit] of TPXRPixelDecoderProc;
    FEncoderLUT:    Array[pf8Bit..pf32Bit] of TPXRPixelEncoderProc;

  Private
    (* Pixel reader implementations, these are the procs used by our
       LUT functin pointers above *)
    Procedure Read08(Const Col,Row:Integer;var outData);
    Procedure Read16(Const Col,Row:Integer;var outData);
    Procedure Read24(Const Col,Row:Integer;var outData);
    Procedure Read32(Const Col,Row:Integer;var outData);

  Private
    (* Pixel writer implementations *)
    Procedure Write08(Const Col,Row:Integer;Const inData);
    Procedure Write16(Const Col,Row:Integer;Const inData);
    Procedure Write24(Const Col,Row:Integer;Const inData);
    Procedure Write32(Const Col,Row:Integer;Const inData);

    Procedure Write32B(Const Col,Row:Integer;const inData);
    Procedure Write24B(Const Col,Row:Integer;const inData);
    Procedure Write16B(Const Col,Row:Integer;const inData);
    Procedure Write15B(Const Col,Row:Integer;const inData);
    Procedure Write08B(Const Col,Row:Integer;const inData);

  Private
    (* Fill rect implementation *)
    Procedure FillRect08(Const Region:TRect;Const inData);
    Procedure FillRect16(Const Region:TRect;Const inData);
    procedure FillRect24(Const Region:TRect;Const inData);
    Procedure FillRect32(Const Region:TRect;Const inData);
    procedure FillRectWithWriter(Const Region:TRect;Const inData);

  (* Our Blitter engine *)
  Private
    Procedure   CPY8bitTo8Bit;
    Procedure   CPY8BitTo15Bit;
    Procedure   CPY8BitTo16Bit;
    Procedure   CPY8BitTo24Bit;
    Procedure   CPY8BitTo32Bit;
    Procedure   CPY15bitTo8Bit;
    Procedure   CPY15BitTo15Bit;
    Procedure   CPY15BitTo16Bit;
    Procedure   CPY15BitTo24Bit;
    Procedure   CPY15BitTo32Bit;
    Procedure   CPY16bitTo8Bit;
    Procedure   CPY16BitTo15Bit;
    Procedure   CPY16BitTo16Bit;
    Procedure   CPY16BitTo24Bit;
    Procedure   CPY16BitTo32Bit;
    Procedure   CPY24bitTo8Bit;
    Procedure   CPY24BitTo15Bit;
    Procedure   CPY24BitTo16Bit;
    Procedure   CPY24BitTo24Bit;
    Procedure   CPY24BitTo32Bit;
    Procedure   CPY32bitTo8Bit;
    Procedure   CPY32BitTo15Bit;
    Procedure   CPY32BitTo16Bit;
    Procedure   CPY32BitTo24Bit;
    Procedure   CPY32BitTo32Bit;

  (* Pixel converters *)
  Private
    Procedure   PxConv08x08(const thispixel;var thatpixel);
    Procedure   PxConv08x15(const thispixel;var thatpixel);
    Procedure   PxConv08x16(const thispixel;var thatpixel);
    Procedure   PxConv08x24(const thispixel;var thatpixel);
    Procedure   PxConv08x32(const thispixel;var thatpixel);

    Procedure   PxConv15x08(const thispixel;var thatpixel);
    Procedure   PxConv15x15(const thispixel;var thatpixel);
    Procedure   PxConv15x16(const thispixel;var thatpixel);
    Procedure   PxConv15x24(const thispixel;var thatpixel);
    Procedure   PxConv15x32(const thispixel;var thatpixel);

    Procedure   PxConv16x08(const thispixel;var thatpixel);
    Procedure   PxConv16x15(const thispixel;var thatpixel);
    Procedure   PxConv16x16(const thispixel;var thatpixel);
    Procedure   PxConv16x24(const thispixel;var thatpixel);
    Procedure   PxConv16x32(const thispixel;var thatpixel);

    Procedure   PxConv24x08(const thispixel;var thatpixel);
    Procedure   PxConv24x15(const thispixel;var thatpixel);
    Procedure   PxConv24x16(const thispixel;var thatpixel);
    Procedure   PxConv24x24(const thispixel;var thatpixel);
    Procedure   PxConv24x32(const thispixel;var thatpixel);

    Procedure   PxConv32x08(const thispixel;var thatpixel);
    Procedure   PxConv32x15(const thispixel;var thatpixel);
    Procedure   PxConv32x16(const thispixel;var thatpixel);
    Procedure   PxConv32x24(const thispixel;var thatpixel);
    Procedure   PxConv32x32(const thispixel;var thatpixel);


  Private
    (* pixel decoders *)
    Procedure   Decode08(const thispixel;var R,G,B:Byte);
    Procedure   Decode15(const thispixel;var R,G,B:Byte);
    Procedure   Decode16(const thispixel;var R,G,B:Byte);
    Procedure   Decode24(const thispixel;var R,G,B:Byte);
    Procedure   Decode32(const thispixel;var R,G,B:Byte);

    (* pixel encoders *)
    Procedure   Encode08(Const R,G,B:Byte; var thatpixel);
    Procedure   Encode15(Const R,G,B:Byte; var thatpixel);
    Procedure   Encode16(Const R,G,B:Byte; var thatpixel);
    Procedure   Encode24(Const R,G,B:Byte; var thatpixel);
    Procedure   Encode32(Const R,G,B:Byte; var thatpixel);

  Private
    Procedure EllipseOutline(Const ARect:TRect);
    Procedure EllipseFilled(Const ARect:TRect);

  Private
    Procedure FillRow(Const Row:Integer;Col,inCount:Integer;var inData);
    Procedure FillCol(Const Col:Integer;Row,inCount:Integer;var inData);

  Protected
    (* Cursor   functionality *)
    Procedure   SetCursor(Value:TPoint);
  Protected
    (* PenStyle *)
    function    getPenStyle:TPXRPenStyle;
    Procedure   SetPenStyle(Value:TPXRPenStyle);
  Protected
    (* Get & Set drawing mode *)
    Function    GetDrawMode:TPXRDrawMode;virtual;
    Procedure   SetDrawMode(Value:TPXRDrawMode);virtual;
  Protected
    (* Methods to get/set current pen color. On setting a new color it is
       converted into a "native color" (see above) which is used for drawing *)
    Function    GetColorValue:TColor;
    Procedure   SetColorValue(Value:TColor);

  Protected
    (* Methods dealing with surface transparency. The concept of a transparent
       surface only comes into play in context with another surface
       (e.g when blitting from A to B) *)
    Function    GetTransparentColorValue:TColor;
    Procedure   SetTransparentColorValue(Value:TColor);
    Procedure   SetTransparent(Value:Boolean);

  Protected
    Function    GetPenAlpha:Byte;
    Procedure   SetPenAlpha(Value:Byte);

  Protected
    (* Methods for plotting pixels through the Pixels[] property.
       These are safe and implements clipping *)
    Function    GetPixel(Const col,Row:Integer):TColor;
    Procedure   SetPixel(Const Col,Row:Integer;Value:TColor);

  Protected
    (* Helper methods that returns information needed for normal pixmap
       operations, these are safe to call without any prior checking *)
    Function    GetPerPixelBits(aFormat:TPixelFormat):Integer;
    Function    GetPerPixelBytes(aFormat:TPixelFormat):Integer;
    Function    GetStrideAlign(Const Value,ElementSize:Integer;
                Const AlignSize:Integer=4):Integer;

  Protected
    (* Method to get the adresse of a pixel. This method does not check
       its parameters, so only call this after checking values. It calls the
       abstract method "GetScanLine" to get it's root adresse *)
    Function    GetPixelAddr(Const Col,Row:Integer):PByte;virtual;

  Protected
    (* Event handler for our current TPXRColor object. Whenever someone
       Alters the RGB value within this class, this event triggers here.
       This means that the corresponding palette index must be found,
       or the colorvalue converted into a native pixel [e.g 8/15/16 bit] *)
    Procedure   HandleColorChanged(Sender:TObject);virtual;

    Procedure   HandleClipRectChanged(Sender:TObject);virtual;

  Protected
    (* Abstract methods. This class provides basic functionality only.
       It is up to the implementor to provide code that actually allocate
       a pixel buffer. See the TPXRSurfaceDIB and TPXRSurfaceRAW for full
       implementations of these methods *)
    Function    GetScanLine(Const Row:Integer):PByte;virtual;abstract;
    Function    GetEmpty:Boolean;virtual;abstract;
    Procedure   ReleaseSurface;virtual;abstract;
    Procedure   AllocSurface(var aWidth,aHeight:Integer;
                var aFormat:TPixelFormat;
                out aPitch:Integer;
                out aBufferSize:Integer);virtual;abstract;
    Procedure   PaletteChange(NewPalette:TPXRPaletteCustom);virtual;abstract;

  public
    (* Methods to convert pixel data between TColor and native, as well as
       blending two pixels directly. These methods must only be called after
       checking the parameters *)
    Procedure   NativePixelToColor(Const Data;var Value:TColor);
    Procedure   ColorToNativePixel(Value:TColor;var Data);

  Public
    Property    Palette:TPXRPaletteCustom read FPalette;
    Property    Color:TPXRPaletteColor read FPenColor;
    Property    ClipRect:TPXRRect read FClipObj;

    Property    Transparent:Boolean
                read FTransparent
                write SetTransparent;
    Property    TransparentColor:TColor
                read  GetTransparentColorValue
                write SetTransparentColorValue;


    Property    ScanLine[Const Row:Integer]:PByte read GetScanline;
    Property    Pixels[Const Col,Row:Integer]:TColor
                read GetPixel write SetPixel;

    Property    Width:Integer read FWidth;
    Property    Pitch:Integer read FPitch;
    Property    Height:Integer read FHeight;
    Property    Empty:Boolean read GetEmpty;
    Property    BoundsRect:TRect read FBounds;

    Property    PerPixelBits:Integer read FBitsPP;
    Property    PerPixelBytes:Integer read FBytesPP;
    Property    PixelFormat:TPixelformat read FFormat;
    Property    Cursor:TPoint read FCursor write SetCursor;
    Property    DrawMode:TPXRDrawMode read GetDrawMode write SetDrawMode;
    Property    PenStyle:TPXRPenStyle read getPenStyle write SetPenStyle;
    Property    PenAlpha:Byte read FPenAlpha write FPenAlpha;

    Procedure   SetPalette(aPalette:TPXRPaletteCustom);

    Function    PixelAddr(Const Col,Row:Integer):PByte;

    Procedure   AdjustToBoundsRect(var Domain:TRect);

    Procedure   LineH(Col,Row:Integer;NumberOfColumns:Integer);
    Procedure   LineV(Col,Row:Integer;NumberOfRows:Integer);
    Procedure   LineTo(Const Col,Row:Integer);
    Procedure   Line(Left,Top,Right,Bottom:Integer);
    Procedure   Bezier(Const Domain:TPXRPointArray);

    procedure   Ellipse(Domain:TRect);

    Procedure   FillRect(Domain:TRect;Const Value:TColor);overload;
    Procedure   FillRect(Domain:TRect);overload;

    Procedure   Rectangle(Const Domain:TRect);overload;
    Procedure   Rectangle(Const Domain:TRect;Const Value:TColor);overload;
    Procedure   DiagonalGrid(Domain:TRect;Const Spacing:Integer=8);
    Procedure   MoveTo(Left,Top:Integer);

    Procedure   StretchDraw(const Source:TPXRSurfaceCustom;
                SourceRect,DestinationRect:TRect);

    Procedure   Draw(Const Source:TPXRSurfaceCustom;
                SourceRect:TRect;DestinationRect:TRect);overload;

    Procedure   Draw(const Source:TPXRSurfaceCustom;
                SourceRect:TRect;Const Col,Row:Integer);overload;

    Procedure   Read(Const Col,Row:Integer;var aData);
    Procedure   WriteClipped(Const Col,Row:Integer);overload;
    Procedure   WriteClipped(Const Col,Row:Integer;Const pxData);overload;
    Procedure   WriteClipped(Const Col,Row:Integer;Const Color:TColor);overload;


    function    getDecoder:TPXRPixelDecoderProc;
    function    getEncoder:TPXRPixelEncoderProc;
    function    getReader:TPXRReaderProc;
    function    getWriter:TPXRWriterProc;

    Procedure   Release;
    Procedure   Alloc(aWidth,aHeight:Integer;aFormat:TPixelFormat);
    Procedure   BeforeDestruction;Override;
    Constructor Create;virtual;
    Destructor  Destroy;Override;

  public
    Property    OnPenStyleAltered:TPXREventPenStyleAltered
                read FOnPenStyleAltered write FOnPenStyleAltered;
    Property    OnDrawModeAltered:TPXREventDrawModeAltered
                read FOnDrawModeAltered write FOnDrawModeAltered;
    Property    OnTransparencyAltered:TPXREventTransparencyAltered
                read FOnTransparencyAltered
                write FOnTransparencyAltered;
    Property    OnPenColorAltered:TPXREventPenColorAltered
                read FOnPenColorAltered
                write FOnPenColorAltered;
    Property    OnTransparentColorAltered:TPXREventTransparentColorAltered
                read FOnTransparentColorAltered
                write FOnTransparentColorAltered;
  End;

  TPXRSurfaceUNI = Class(TPXRSurfaceCustom)
  Private
    FBuffer:  PByte;
    FBufSize: Integer;
  Protected
    Procedure PaletteChange(NewPalette:TPXRPaletteCustom);override;
    Function  GetScanLine(Const Row:Integer):PByte;override;
    Function  GetEmpty:Boolean;override;
    Procedure ReleaseSurface;override;
    Procedure AllocSurface(var aWidth,aHeight:Integer;
              var aFormat:TPixelFormat;
              out aPitch:Integer;
              out aBufferSize:Integer);override;
  End;

  {$IFDEF MSWINDOWS}
  TPXRSurfaceDIB = Class(TPXRSurfaceCustom)
  Private
    FDC:      HDC;
    FBitmap:  HBitmap;
    FOldBmp:  HBitmap;
    FBuffer:  Pointer;
    FDInfo:   PBitmapInfo;
  Protected
    Procedure PaletteChange(NewPalette:TPXRPaletteCustom);override;
    Function  GetScanLine(Const Row:Integer):PByte;override;
    Function  GetEmpty:Boolean;override;
    Procedure ReleaseSurface;override;
    Procedure AllocSurface(var aWidth,aHeight:Integer;
              var aFormat:TPixelFormat;
              out aPitch:Integer;
              out aBufferSize:Integer);override;
  Public
    Property  DC:HDC read FDC;
    Property  Bitmap:HBitmap read FBitmap;
  End;
  {$ENDIF}

  Const
  ERR_SLSURFACE_NotAllocated =
  'Surface is not allocated';

  ERR_SLSURFACE_INVALIDCORDINATE =
  'Invalid pixel co-ordinates [%d,%d] error';

  ERR_SLSURFACE_UNSUPPORTEDFORMAT =
  'Unsupported pixelformat error';

  ERR_SLSURFACE_FAILEDALLOCATE =
  'Failed to allocate surface memory [%s]';

  ERR_SLSURFACE_FAILEINSTALLPALETTE =
  'Failed to install palette object [%s]';

  ERR_SLSURFACE_TARGETISNIL =
  'Target surface is NIL or invalid error';

  ERR_SLSURFACE_TARGETNotAllocated =
  'Target surface is empty error';

  ERR_SLSURFACE_SOURCEISNIL =
  'Source surface is NIL or invalid error';


  const
  ERR_SLCOLOR_SOURCEBUFFER_INVALID
  = 'Failed to extract color, source is NIL';

  ERR_SLCOLOR_TARGETBUFFER_INVALID
  = 'Failed to export color, target is NIL';

  Const

  ERR_SLPALETTE_PALETTEREADONLY =
  'Palette is read-only, colors cannot be altered error';

  ERR_SLPALETTE_INVALIDCOLORINDEX =
  'Invalid palette color index, expected %d..%d, not %d';

  ERR_SLPALETTE_ASSIGNToREADONLY =
  'Failed to assign palette to read-only target';

  CNT_SLPALETTE_NETSCAPE_COUNT = 216;

  const
  ERR_SLRECT_InvalidRect    = 'Invalid rectangle error';
  ERR_SLRECT_InvalidValues  = 'Invalid values for a rectangle error';


  Const
  PXR_NULLRECT:TRect =(left:0;top:0;right:0;bottom:0);

  Const
  PerPixel_Bits:  Array[pf8bit..pf32bit] of Integer = (8,16,16,24,32);
  PerPixel_Bytes: Array[pf8bit..pf32bit] of Integer = (1,2,2,3,4);


  Procedure PXR_SwapInt(Var Primary,Secondary:Integer);
  Function  PXR_MakePoint(Const Left,Top:Integer):TPoint;
  Function  PXR_Diff(Const Primary,Secondary:Integer;
            Const Exclusive:Boolean=False):Integer;
  Function  PXR_Positive(Const Value:Integer):Integer;

  Function PXR_RectRows(Const Value:TRect):Integer;
  Function PXR_RectCols(Const Value:TRect):Integer;

  implementation

  Function PXR_RectRows(Const Value:TRect):Integer;
  Begin
    result:=Value.Bottom;
    dec(result,Value.Top);
    if Value.top<=0 then
    inc(result);
  end;

  Function PXR_RectCols(Const Value:TRect):Integer;
  Begin
    result:=Value.Right;
    dec(result,value.Left);
    if Value.Left<=0 then
    inc(result);
  end;


  Function PXR_MakePoint(Const Left,Top:Integer):TPoint;
  Begin
    result.x:=Left;
    result.y:=Top;
  end;

  Function  PXR_Diff(Const Primary,Secondary:Integer;
            Const Exclusive:Boolean=False):Integer;
  Begin
    If Primary<>Secondary then
    Begin
      If Primary>Secondary then
      result:=Primary-Secondary else
      result:=Secondary-Primary;

      If Exclusive then
      If (Primary<1) or (Secondary<1) then
      inc(result);

      If result<0 then
      result:=Result-1 xor -1;
    end else
    result:=0;
  end;

  Function PXR_Positive(Const Value:Integer):Integer;
  Begin
    If Value<0 then
    Result:=Value-1 xor -1 else
    result:=Value;
  end;

  Procedure PXR_SwapInt(Var Primary,Secondary:Integer);
  var
    FTemp: Integer;
  Begin
    FTemp:=Primary;
    Primary:=Secondary;
    Secondary:=FTemp;
  end;

  Function PXR_LineClip(Domain:TRect;
           var Left,Top,Right,Bottom:Integer):Boolean;
  var
    n:      Integer;
    xdiff:  Integer;
    yDiff:  Integer;
    a,b:    Single;
  begin
    (* realize domain if inverted *)
    If (Domain.right<Domain.left)
    or (Domain.Bottom<Domain.top) then
    TPXRRect.Realize(Domain);

    result:=TPXRRect.IsValid(Domain);
    If result then
    Begin
      (* determine slope difference *)
      xDiff:=Left-Right;
      yDiff:=Top-Bottom;

      (* pure vertical line *)
      if xdiff=0 then
      begin
        Top:=math.EnsureRange(top,domain.top,domain.bottom);
        bottom:=math.EnsureRange(bottom,domain.Top,domain.bottom);

        if Top>Bottom then
        PXR_SwapInt(Top,Bottom);

        result:=(Left>=Domain.Left)
        and     (right<=Domain.Right)
        and     (top>=Domain.Top)
        and     (bottom<=Domain.Bottom);
      end else

      (* pure horizontal line *)
      if yDiff=0 then
      begin
        Left:=math.EnsureRange(Left,domain.left,domain.right);
        right:=math.EnsureRange(right,domain.left,domain.right);

        If right<Left then
        PXR_SwapInt(right,left);
        result:=(Left>=Domain.Left)
        and     (right<=Domain.Right)
        and     (top>=Domain.Top)
        and     (bottom<=Domain.Bottom);
      end else

      (* Ensure visible results *)
      if ((Top<Domain.top) and (Bottom<Domain.top))
      or ((Top>Domain.bottom) and (Bottom>Domain.bottom))
      or ((Left>Domain.right) and (Right>Domain.right))
      or ((Left<Domain.left) and (Right<Domain.left)) then
      Result:=False else
      Begin
        (* sloped line *)
        a:=ydiff / xdiff;
        b:=(Left * Bottom - Right * Top) / xdiff;

        if (Top<Domain.top) or (Bottom<Domain.top) then
        begin
          n := round ((Domain.top - b) / a);
          if (n>=Domain.left) and (n<=Domain.right) then
          if (Top<Domain.top) then
          begin
            Left:=n;
            Top:=Domain.top;
          end else
          begin
            Right:=n;
            Bottom:=Domain.top;
          end;
        end;

        if (Top>Domain.bottom) or (Bottom>Domain.bottom) then
        begin
          n := round ((Domain.bottom - b) / a);
          if (n>=Domain.left) and (n<=Domain.right) then
          if (Top>Domain.bottom) then
          begin
            Left:=n;
            Top:=Domain.bottom;
          end else
          begin
            Right:=n;
            Bottom:=Domain.bottom;
          end;
        end;

        if (Left<Domain.left) or (Right<Domain.left) then
        begin
          n:=round((Domain.left * a) + b);
          if (n <= Domain.bottom) and (n>=Domain.top) then
          if (Left<Domain.left) then
          begin
            Left:=Domain.left;
            Top:=n;
          end else
          begin
            Right:=Domain.left;
            Bottom:=n;
          end;
        end;

        if (Left>Domain.right) or (Right>Domain.right) then
        begin
          n:=round((Domain.right * a) + b);
          if (n<=Domain.bottom) and (n>=Domain.top) then
          if (Left>Domain.right) then
          begin
            Left:=Domain.right;
            Top:=n;
          end else
          begin
            Right:=Domain.right;
            Bottom:=n;
          end;
        end;
      end;
    end;
  end;

  //###########################################################################
  //  TPXRSurfaceCustom
  //###########################################################################

  Constructor TPXRSurfaceCustom.Create;
  Begin
    inherited;
    FPenColor:=TPXRPaletteColor.Create;
    FPenColor.OnColorChanged:=HandleColorChanged;

    FClipObj:=TPXRRect.Create;
    FClipObj.OnRectAltered:=HandleClipRectChanged;

    FEllipseLUTEX[stOutline]:=EllipseOutline;
    FEllipseLUTEX[stSolid]:=EllipseFilled;


    FDecoderLUT[pf8Bit]:=self.Decode08;
    FDecoderLUT[pf15Bit]:=Decode15;
    FDecoderLUT[pf16Bit]:=Decode16;
    FDecoderLUT[pf24Bit]:=Decode24;
    FDecoderLUT[pf32Bit]:=Decode32;

    FEncoderLUT[pf8Bit]:=Encode08;
    FEncoderLUT[pf15Bit]:=Encode15;
    FEncoderLUT[pf16Bit]:=Encode16;
    FEncoderLUT[pf24Bit]:=Encode24;
    FEncoderLUT[pf32Bit]:=Encode32;

    (* Setup the blitter *)
    FBlitterLUT[pf8bit,pf8bit]:=CPY8bitTo8Bit;
    FBlitterLUT[pf8bit,pf15Bit]:=CPY8bitTo15Bit;
    FBlitterLUT[pf8bit,pf16Bit]:=CPY8bitTo16Bit;
    FBlitterLUT[pf8bit,pf24Bit]:=CPY8bitTo24Bit;
    FBlitterLUT[pf8bit,pf32Bit]:=CPY8bitTo32Bit;
    FBlitterLUT[pf15Bit,pf8bit]:=CPY15bitTo8Bit;
    FBlitterLUT[pf15Bit,pf15Bit]:=CPY15bitTo15Bit;
    FBlitterLUT[pf15Bit,pf16Bit]:=CPY15bitTo16Bit;
    FBlitterLUT[pf15Bit,pf24Bit]:=CPY15bitTo24Bit;
    FBlitterLUT[pf15Bit,pf32Bit]:=CPY15bitTo32Bit;
    FBlitterLUT[pf16Bit,pf8Bit]:=CPY16bitTo8Bit;
    FBlitterLUT[pf16Bit,pf15Bit]:=CPY16bitTo15Bit;
    FBlitterLUT[pf16Bit,pf16Bit]:=CPY16bitTo16Bit;
    FBlitterLUT[pf16Bit,pf24Bit]:=CPY16bitTo24Bit;
    FBlitterLUT[pf16Bit,pf32Bit]:=CPY16bitTo32Bit;
    FBlitterLUT[pf24Bit,pf8Bit]:=CPY24bitTo8Bit;
    FBlitterLUT[pf24Bit,pf15Bit]:=CPY24bitTo15Bit;
    FBlitterLUT[pf24Bit,pf16Bit]:=CPY24bitTo16Bit;
    FBlitterLUT[pf24Bit,pf24Bit]:=CPY24bitTo24Bit;
    FBlitterLUT[pf24Bit,pf32Bit]:=CPY24bitTo32Bit;
    FBlitterLUT[pf32Bit,pf8Bit]:=CPY32bitTo8Bit;
    FBlitterLUT[pf32Bit,pf15Bit]:=CPY32bitTo15Bit;
    FBlitterLUT[pf32Bit,pf16Bit]:=CPY32bitTo16Bit;
    FBlitterLUT[pf32Bit,pf24Bit]:=CPY32bitTo24Bit;
    FBlitterLUT[pf32Bit,pf32Bit]:=CPY32bitTo32Bit;

    (* Setup the pixel converters *)
    FPXTraLUT[pf8bit,pf8bit]:=PxConv08x08;
    FPXTraLUT[pf8bit,pf15Bit]:=PxConv08x15;
    FPXTraLUT[pf8bit,pf16Bit]:=PxConv08x16;
    FPXTraLUT[pf8bit,pf24Bit]:=PxConv08x24;
    FPXTraLUT[pf8bit,pf32Bit]:=PxConv08x32;
    FPXTraLUT[pf15Bit,pf8bit]:=PxConv15x08;
    FPXTraLUT[pf15Bit,pf15Bit]:=PxConv15x15;
    FPXTraLUT[pf15Bit,pf16Bit]:=PxConv15x16;
    FPXTraLUT[pf15Bit,pf24Bit]:=PxConv15x24;
    FPXTraLUT[pf15Bit,pf32Bit]:=PxConv15x32;
    FPXTraLUT[pf16Bit,pf8Bit]:=PxConv16x08;
    FPXTraLUT[pf16Bit,pf15Bit]:=PxConv16x15;
    FPXTraLUT[pf16Bit,pf16Bit]:=PxConv16x16;
    FPXTraLUT[pf16Bit,pf24Bit]:=PxConv16x24;
    FPXTraLUT[pf16Bit,pf32Bit]:=PxConv16x32;
    FPXTraLUT[pf24Bit,pf8Bit]:=PxConv24x08;
    FPXTraLUT[pf24Bit,pf15Bit]:=PxConv24x15;
    FPXTraLUT[pf24Bit,pf16Bit]:=PxConv24x16;
    FPXTraLUT[pf24Bit,pf24Bit]:=PxConv24x24;
    FPXTraLUT[pf24Bit,pf32Bit]:=PxConv24x32;
    FPXTraLUT[pf32Bit,pf8Bit]:=PxConv32x08;
    FPXTraLUT[pf32Bit,pf15Bit]:=PxConv32x15;
    FPXTraLUT[pf32Bit,pf16Bit]:=PxConv32x16;
    FPXTraLUT[pf32Bit,pf24Bit]:=PxConv32x24;
    FPXTraLUT[pf32Bit,pf32Bit]:=PxConv32x32;

    (*Pixel Reader matrix *)
    FReadLUTEX[pf8bit]:=Read08;
    FReadLUTEX[pf15bit]:=Read16; //Plain 16bit read
    FReadLUTEX[pf16bit]:=Read16;
    FReadLUTEX[pf24bit]:=Read24;
    FReadLUTEX[pf32bit]:=Read32;

    (* Pixel Writer matrix *)
    FWriteLUTEX[pf8bit,dmCopy]:=Write08;
    FWriteLUTEX[pf8bit,dmBlend]:=Write08B;
    FWriteLUTEX[pf15bit,dmCopy]:=Write16; //plain 16bit write
    FWriteLUTEX[pf15bit,dmBlend]:=Write15B;
    FWriteLUTEX[pf16bit,dmCopy]:=Write16;
    FWriteLUTEX[pf16bit,dmBlend]:=Write16B;
    FWriteLUTEX[pf24bit,dmCopy]:=Write24;
    FWriteLUTEX[pf24bit,dmBlend]:=Write24B;
    FWriteLUTEX[pf32bit,dmCopy]:=Write32;
    FWriteLUTEX[pf32bit,dmBlend]:=Write32B;

    (* pixel "FillRect" matrix *)
    FFillRectLUTEX[pf8bit,dmCopy]:=FillRect08;
    FFillRectLUTEX[pf8bit,dmBlend]:=FillRectWithWriter;
    FFillRectLUTEX[pf15bit,dmCopy]:=FillRect16;
    FFillRectLUTEX[pf15bit,dmBlend]:=FillRectWithWriter;
    FFillRectLUTEX[pf16bit,dmCopy]:=FillRect16;
    FFillRectLUTEX[pf16bit,dmBlend]:=FillRectWithWriter;
    FFillRectLUTEX[pf24bit,dmCopy]:=FillRect24;
    FFillRectLUTEX[pf24bit,dmBlend]:=FillRectWithWriter;
    FFillRectLUTEX[pf32bit,dmCopy]:=FillRect32;
    FFillRectLUTEX[pf32bit,dmBlend]:=FillRectWithWriter;
  end;

  Destructor TPXRSurfaceCustom.Destroy;
  Begin
    FreeAndNIL(FPenColor);
    FreeAndNIL(FClipObj);
    Inherited;
  end;

  Procedure TPXRSurfaceCustom.BeforeDestruction;
  Begin
    If not GetEmpty then
    Release;
    inherited;
  end;

  Procedure TPXRSurfaceCustom.HandleClipRectChanged(Sender:TObject);
  Begin
    FClipRect:=FClipObj.Value;
  end;

  function TPXRSurfaceCustom.getDecoder:TPXRPixelDecoderProc;
  Begin
    result:=FDecoderLUT[FFormat];
  end;

  function TPXRSurfaceCustom.getEncoder:TPXRPixelEncoderProc;
  Begin
    result:=FEncoderLUT[FFormat];
  end;

  function TPXRSurfaceCustom.getReader:TPXRReaderProc;
  Begin
    result:=FReadLUT;
  end;

  function TPXRSurfaceCustom.getWriter:TPXRWriterProc;
  Begin
    result:=FWriteLUT;
  end;

  Procedure TPXRSurfaceCustom.Draw(Const Source:TPXRSurfaceCustom;
            SourceRect:TRect;DestinationRect:TRect);
  var
    srcwidth:   Integer;
    srcheight:  Integer;
    dstwidth:   Integer;
    dstheight:  Integer;
  Begin
    (* Get source width & height *)
    srcWidth:=sourcerect.right-sourcerect.left;
    srcheight:=sourcerect.bottom-sourcerect.Top;

    (* get target width & height *)
    dstwidth:=DestinationRect.right-DestinationRect.left;
    dstHeight:=DestinationRect.bottom-DestinationRect.Top;

    (* Check if width & height is same, if so - we do a normal copy *)
    if  (srcwidth=dstwidth)
    and (srcHeight=dstHeight) then
    Draw(source,sourcerect,FCopydstRect.left,FCopydstRect.top) else

    (* not same size, so we do a stretch blit instead *)
    StretchDraw(source,SourceRect,DestinationRect);
  end;

  Procedure TPXRSurfaceCustom.Draw(const Source:TPXRSurfaceCustom;
            SourceRect:TRect;Const Col,Row:Integer);
  var
    y:          Integer;
    FSrcPitch:  Integer;
    FDstPitch:  Integer;
    FPixels:    Integer;
    FSource:    PByte;
    FTarget:    PByte;
    FTemp:      TRect;
    xoff,
    yoff:       Integer;
  Begin
    If GetEmpty=False then
    Begin
      If (source<>NIL) and (source<>self) then
      Begin
        If source.Empty=False then
        Begin
          (* get pixel copier for source -> target formats *)
          FCopyLPC:=FBlitterLUT[source.PixelFormat,PixelFormat];
          
          (* get source rectangle *)
          FCopysrcRect:=SourceRect;
          Source.AdjustToBoundsRect(FCopySrcRect);

          (* build target rectangle *)
          FTemp.left:=col;
          FTemp.top:=row;
          FTemp.right:=col + (FCopysrcRect.Right-FCopysrcRect.left);
          FTemp.bottom:=row + (FCopysrcRect.bottom - FCopysrcRect.Top);

          If TPXRRect.Intersect(FTemp,FClipRect,FCopydstRect) then
          Begin

            (* Clip & adjust offset-left *)
            if (FTemp.left<FCopyDstRect.Left) then
            Begin
              xoff:=abs(FTemp.left - FCopyDstRect.Left);
              FCopysrcRect.Left:=FCopysrcRect.Left + xoff;
              FCopydstRect.Right:=FCopydstRect.Right - xoff;
            end;

            (* Clip & adjust offset-top *)
            if (FTemp.top<FCopyDstRect.top) then
            Begin
              yoff:=abs(FTemp.top - FCopyDstRect.top);
              FCopysrcRect.top:=FCopysrcRect.top + yoff;
              FCopydstRect.bottom:=FCopydstRect.bottom - yoff;
            end;

            (* Any visible output? *)
            if ((FCopysrcRect.right-FCopysrcRect.left)<1)
            or ((FCopysrcRect.Bottom-FCopysrcRect.Top)<1)
            or ((FCopydstRect.right-FCopydstRect.left)<1)
            or ((FCopydstRect.Bottom-FCopydstRect.Top)<1) then
            exit;

            (* Get source & target pointers *)
            FSource:=source.PixelAddr(FCopysrcRect.left,FCopysrcRect.top);
            FTarget:=GetPixelAddr(FCopydstRect.left,FCopydstRect.top);

            FCopyTrans:=Source.Transparent;
            If FCopyTrans then
            Source.ColorToNativePixel(Source.TransparentColor,FCopyKey);

            If source.PixelFormat=pf8Bit then
            FCopyPal:=Source.Palette;

            FPixels:=PXR_RectCols(FCopydstRect);

            FSrcPitch:=Source.Pitch;
            FDstPitch:=Pitch;

            {If  (Source.PixelFormat=FFormat) then
            Begin   }
              y:=FCopydstRect.top;
              while y<=FCopydstRect.Bottom do
              Begin
                FCopyCnt:=FPixels;
                FCopySrc:=FSource;
                FCopyDst:=FTarget;
                FCopyLpc;
                inc(FSource,FSrcPitch);
                inc(FTarget,FDstPitch);
                inc(y);
              end;
            //end;

          end;
        end;
      end;
    end;
  end;


  Procedure TPXRSurfaceCustom.StretchDraw(const Source:TPXRSurfaceCustom;
            SourceRect,DestinationRect:TRect);
  const
    FACTOR = 1 shl 16; // scale factor for fixed point math
  var
    sw, sh: Integer;
    dw, dh: Integer;
    x,y:    Integer;
    sx, sy: Integer;
    dx, dy: Integer;
    tx, ty: Integer;
    //FColor: TColor;
    FTemp:  Longword;
    FAddr:  PByte;
    FPxTrans: TPXRPixelCopyProc;
    mSrcAddr:  PByte;
    mDstAddr:  PByte;

    FDecoder: TPXRPixelDecoderProc;
    FEncoder: TPXRpixelEncoderProc;
    r,g,b:  byte;

  Begin
    If GetEmpty=False then
    Begin
      If TPXRRect.IsValid(destinationrect) then
      Begin
        If source<>NIL then
        Begin
          If source.Empty=False then
          Begin
            source.AdjustToBoundsRect(sourcerect);
            if TPXRRect.IsValid(sourcerect) then
            Begin
              (* get source width & height *)
              sw:=sourcerect.right-sourcerect.left+1;
              sh:=sourcerect.bottom-sourcerect.top+1;

              (* get target width & height *)
              dw:=destinationrect.right-destinationrect.left+1;
              dh:=destinationrect.bottom-destinationrect.top+1;

              (* calculate skip for X *)
              dx:= sw * FACTOR div dw;

              (* calculate skip for Y *)
              dy:= sh * FACTOR div dh;

              (* calculate start offset for Y *)
              sy:= sourcerect.Top * FACTOR;

              If source.Transparent=False then
              Begin
                (* Get pixel translator *)
                FPxTrans:=FPXTraLUT[source.Pixelformat,FFormat];

                (* 8Bit involved? *)
                if source.PixelFormat = pf8bit then
                FCopyPal:=source.Palette;
                if (FCopyPal=NIL) and (FPalette<>NIL) then
                FCopyPal:=FPalette;

                (* setup Co/DEC *)
                FDecoder:=Source.GetDecoder();
                FEncoder:=Self.GetEncoder();

                for y:=destinationrect.Top to destinationrect.Bottom do
                begin
                  ty:=sy div FACTOR;
                  sx:= sourcerect.Left * FACTOR;
                  mDstAddr:=GetPixelAddr(destinationrect.left,y);
                  for x:=destinationrect.left to destinationrect.right do
                  Begin
                    If  (x>=FCliprect.Left)
                    and (x<=FCliprect.right)
                    and (y>=FCliprect.top)
                    and (y<=FCliprect.bottom) then
                    Begin
                      tx:=sx div FACTOR;
                      mSrcAddr:=Source.PixelAddr(tx,ty);

                      (* Decode pixel from source *)
                      FDecoder(mSrcAddr^,r,g,b);

                      (* Encode pixel to target *)
                      FEncoder(r,g,b,mDstAddr^);
                    end;

                    (* update target adresse *)
                    inc(mDstAddr,PerPixelBytes);
                    inc(sx,dx);
                  end;
                  inc(sy,dy);
                end;
              end else
              Begin
                (* get colorkey from source *)
                FCopyKey:=Source.TransparentColor;

                for y:=destinationrect.Top to destinationrect.Bottom do
                begin
                  ty:=sy div FACTOR;
                  sx:= sourcerect.Left * FACTOR;
                  FAddr:=GetPixelAddr(destinationrect.left,y);
                  for x:=destinationrect.left to destinationrect.right do
                  Begin
                    If  (x>=Cliprect.Left)
                    and (x<=Cliprect.right)
                    and (y>=Cliprect.top)
                    and (y<=cliprect.bottom) then
                    Begin
                      (* get pixel from source *)
                      tx:=sx div FACTOR;
                      Source.Read(tx,ty,FColor);

                      If FColor<>FCopyKey then
                      Begin
                        (* convert to native pixel *)
                        ColorToNativePixel(FColor,FTemp);

                        FWriteLUT(x,y,FTemp);
                      end;
                    end;

                    (* update target adresse *)
                    inc(FAddr,PerPixelBytes);
                    inc(sx,dx);
                  end;
                  inc(sy,dy);
                end;
              end;

            end;
          end;
        end;
      end;
    end;
  end;

  (* Pixel reader implementations *)
  Procedure TPXRSurfaceCustom.Read08(Const Col,Row:Integer;var outData);
  Begin
    Byte(outData):=PByte(GetPixelAddr(Col,Row))^;
  end;

  Procedure TPXRSurfaceCustom.Read16(Const Col,Row:Integer;var outData);
  begin
    Word(OutData):=PWord(GetPixelAddr(Col,Row))^;
  end;

  Procedure TPXRSurfaceCustom.Read24(Const Col,Row:Integer;var outData);
  begin
    TRGBTriple(OutData):=PRGBTriple(GetPixelAddr(Col,Row))^;
  end;

  Procedure TPXRSurfaceCustom.Read32(Const Col,Row:Integer;var outData);
  Begin
    Longword(outData):=PLongword(GetPixelAddr(Col,Row))^;
  end;

  (* Pixel writer implementations *)
  Procedure TPXRSurfaceCustom.Write08(Const Col,Row:Integer;Const inData);
  Begin
    PByte(PixelAddr(Col,Row))^:=Byte(inData);
  end;

  Procedure TPXRSurfaceCustom.Write16(Const Col,Row:Integer;Const inData);
  Begin
    PWord(GetPixelAddr(Col,Row))^:=Word(inData);
  end;

  Procedure TPXRSurfaceCustom.Write24(Const Col,Row:Integer;Const inData);
  Begin
    PRGBTriple(GetPixelAddr(Col,Row))^:=TRGBTriple(inData);
  end;

  Procedure TPXRSurfaceCustom.Write32(Const Col,Row:Integer;Const inData);
  Begin
    PLongword(GetPixelAddr(Col,Row))^:=Longword(inData);
  end;

  Procedure TPXRSurfaceCustom.Write32B(Const Col,Row:Integer;const inData);
  var
    rs,gs,bs,
    rd,gd,bd,
    rx,gx,bx: Byte;
    FAddr:  Pbyte;
  Begin
    (* Extract RGB data from source *)
    TPXRColorCustom.RGBFrom32(indata,rs,gs,bs);

    (* Extract RGB data from target *)
    FAddr:=GetPixelAddr(col,row);
    TPXRColorCustom.RGBFrom32(FAddr^,rd,gd,bd);

    (* Blend triplets *)
    rx:=byte(((rs-rd) * FPenAlpha) shr 8 + rd);
    gx:=byte(((gs-gd) * FPenAlpha) shr 8 + gd);
    bx:=byte(((bs-bd) * FPenAlpha) shr 8 + bd);

    TPXRColorCustom.RGBTo32(FAddr^,rx,gx,bx);
  end;

  Procedure TPXRSurfaceCustom.Write24B(Const Col,Row:Integer;const inData);
  var
    rs,gs,bs,
    rd,gd,bd,
    rx,gx,bx: Byte;
    FAddr:  Pbyte;
  Begin
    (* Extract RGB data from source *)
    TPXRColorCustom.RGBFrom24(indata,rs,gs,bs);

    (* Extract RGB data from target *)
    FAddr:=GetPixelAddr(col,row);
    TPXRColorCustom.RGBFrom24(FAddr^,rd,gd,bd);

    (* Blend triplets *)
    rx:=byte(((rs-rd) * FPenAlpha) shr 8 + rd);
    gx:=byte(((gs-gd) * FPenAlpha) shr 8 + gd);
    bx:=byte(((bs-bd) * FPenAlpha) shr 8 + bd);

    (* write result to pixel buffer *)
    TPXRColorCustom.RGBTo24(FAddr^,rx,gx,bx);
  end;

  Procedure TPXRSurfaceCustom.Write16B(Const Col,Row:Integer;const inData);
  var
    rs,gs,bs,
    rd,gd,bd,
    rx,gx,bx: Byte;
    FAddr:  Pbyte;
  Begin
    (* Extract RGB data from source *)
    TPXRColorCustom.RGBFrom16(indata,rs,gs,bs);

    (* Extract RGB data from target *)
    FAddr:=GetPixelAddr(col,row);
    TPXRColorCustom.RGBFrom16(FAddr^,rd,gd,bd);

    (* Blend triplets *)
    rx:=byte(((rs-rd) * FPenAlpha) shr 8 + rd);
    gx:=byte(((gs-gd) * FPenAlpha) shr 8 + gd);
    bx:=byte(((bs-bd) * FPenAlpha) shr 8 + bd);

    (* write result to pixel buffer *)
    TPXRColorCustom.RGBTo16(FAddr^,rx,gx,bx);
  end;

  Procedure TPXRSurfaceCustom.Write15B(Const Col,Row:Integer;const inData);
  var
    rs,gs,bs,
    rd,gd,bd,
    rx,gx,bx: Byte;
    FAddr:  Pbyte;
  Begin
    (* Extract RGB data from source *)
    TPXRColorCustom.RGBFrom15(indata,rs,gs,bs);

    (* Extract RGB data from target *)
    FAddr:=GetPixelAddr(col,row);
    TPXRColorCustom.RGBFrom15(FAddr^,rd,gd,bd);

    (* Blend triplets *)
    rx:=byte(((rs-rd) * FPenAlpha) shr 8 + rd);
    gx:=byte(((gs-gd) * FPenAlpha) shr 8 + gd);
    bx:=byte(((bs-bd) * FPenAlpha) shr 8 + bd);

    (* write result to pixel buffer *)
    TPXRColorCustom.RGBTo15(FAddr^,rx,gx,bx);
  end;

  Procedure TPXRSurfaceCustom.Write08B(Const Col,Row:Integer;const inData);
  var
    rs,gs,bs,
    rd,gd,bd,
    rx,gx,bx: Byte;
    FAddr:  Pbyte;
  Begin
    (* Extract RGB data from source *)
    TPXRPaletteColor.RGBFrom08(Fpalette,inData,rs,gs,bs);

    (* Extract RGB data from target *)
    FAddr:=GetPixelAddr(col,row);
    TPXRPaletteColor.RGBFrom08(Fpalette,FAddr^,rd,gd,bd);

    (* Blend triplets *)
    rx:=byte(((rs-rd) * FPenAlpha) shr 8 + rd);
    gx:=byte(((gs-gd) * FPenAlpha) shr 8 + gd);
    bx:=byte(((bs-bd) * FPenAlpha) shr 8 + bd);

    (* Look up the result *)
    FAddr^:=Fpalette.Match(rx,gx,bx);
  end;

  Procedure TPXRSurfaceCustom.HandleColorChanged(Sender:TObject);
  Begin
    If not GetEmpty then
    SetColorValue(FPenColor.ColorRef);
  end;

  Procedure TPXRSurfaceCustom.SetPalette(aPalette:TPXRPaletteCustom);
  Begin
    (* Make sure its not the same palette as we already have *)
    If aPalette<>FPalette then
    Begin
      (* Release current palette *)
      if FPalette<>NIL then
      FreeAndNIL(FPalette);

      (* Keep new palette *)
      FPalette:=aPalette;

      (* Trigger palette change event. Since this method is abstract
      we have to take into concideration that an exception might occur. *)
      try
        PaletteChange(FPalette);
      except
        on e: exception do
        Begin
          FreeAndNIL(FPalette);
          Raise EPXRSurfaceCustom.CreateFmt
          (ERR_SLSURFACE_FAILEINSTALLPALETTE,[e.message]);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.DiagonalGrid(Domain:TRect;
            Const Spacing:Integer=8);
  var
    x,z,ftimes:   Integer;
    wd,hd:        Integer;
    FOldRect:     TRect;
    FClipper:     Boolean;
  Begin
    If not GetEmpty then
    Begin
      if TPXRRect.IsValid(Domain)
      and TPXRRect.Intersect(Domain,FClipObj.Value,Domain) then
      Begin
        FClipper:=FClipObj.Empty=False;
        If FClipper then
        FOldRect:=FClipRect;
        FClipObj.SetRect(Domain);

        (* adjust width & height bounds *)
        wd:=(Domain.right-Domain.left)+1;
        hd:=(Domain.bottom-Domain.top)+1;
        inc(wd); inc(hd);

        x:=Spacing;
        ftimes:=((wd + hd) div Spacing)-1;

        for z:=1 to FTimes do
        Begin
          Line(Domain.left,Domain.top+x,Domain.left+x,Domain.top);
          inc(x,Spacing);
        end;

        If FClipper then
        FClipObj.SetRect(FOldRect) else
        FClipObj.SetRect(FBounds);
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.EllipseFilled(Const ARect:TRect);
  var
    cx:           Integer;
    cx1:          Integer;
    cy1:          Integer;
    cx2:          Integer;
    cy2:          Integer;
    y1:           Integer;
    y2:           Integer;
    err:          Integer;
    x:            Integer;
    y:            Integer;
    dx:           Integer;
    dy:           Integer;
    XChange:      Integer;
    YChange:      Integer;
    tASqr:        Integer;
    tBSqr:        Integer;
    StopX:        Integer;
    StopY:        Integer;
    XRadius:      Integer;
    YRadius:      Integer;
    FClipResult:  TPXRRectExposure;

    procedure Plot2Lines(x,y:Integer);
    var
      sx: Integer;
    begin
      sx:=cx+x+x;
      FillRow(cy1-y,cx1-x,sx,FColorRaw);
      FillRow(cy2+y,cx1-x, sx,FColorRaw);
    end;

  begin
    (* only render if the result is visible *)
    FClipResult:=TPXRRect.isVisible(FClipRect,ARect);
    If FClipResult>esNone then
    Begin
      dx:=ARect.Right  - ARect.Left;
      dy:=ARect.Bottom - ARect.Top;

      if (dx<3) or (dy<3) then
      FillRect(ARect) else
      Begin
        XRadius := (dx-1) div 2;
        YRadius := (dy-1) div 2;
        cx1 := ARect.Left+XRadius;
        cy1 := ARect.Top+YRadius;
        cx2 := cx1;
        cy2 := cy1;
        if not odd(dx) then inc(cx2);
        if not odd(dy) then inc(cy2);
        cx := cx2-cx1+1;

        { precompute }
        tASqr := 2*sqr(XRadius);
        tBSqr := 2*sqr(YRadius);

        X:= XRadius;
        Y:=0;
        Err:=0;
        StopY:=0;
        XChange:=sqr(YRadius)*(1-2*XRadius);
        YChange:=sqr(XRadius);
        StopX:=tBSqr*XRadius;

        { 1st set of points }
        while (StopX >= StopY) do
        begin
          Plot2Lines(x,y);
          inc(y);
          inc(StopY, tASqr);
          inc(Err, YChange);
          inc(YChange, tASqr);
          if (2*Err+XChange)>0 then
          begin
            dec(x);
            dec(StopX, tBSqr);
            inc(Err, XChange);
            inc(XChange, tBSqr);
          end;
        end;
        y1:=y;
        y2:=y;

        { 2nd set of points }
        x := 0;
        y := YRadius;
        XChange:=sqr(YRadius);
        YChange:=sqr(XRadius) * (1-2*YRadius);
        Err := 0;
        StopX := 0;
        StopY := tASqr*YRadius;
        while (StopX <= StopY) do
        begin
          Plot2Lines(x,y);
          inc(x);
          inc(StopX, tBSqr);
          inc(Err, XChange);
          inc(XChange, tBSqr);
          y2 := y;
          if (2*Err+YChange)>0 then
          begin
            dec(y);
            dec(StopY, tASqr);
            inc(Err, YChange);
            inc(YChange, tASqr);
          end;
        end;

        { fill the possible gap }
        dec(x);
        for y:=y1 to y2-1 do
        Plot2Lines(x,y);
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.EllipseOutline(Const ARect:TRect);
  var
    cx1, cy1, cx2, cy2: Integer;
    dx, dy: Integer;
    x, y: Integer;
    XChange, YChange: Integer;
    Err: Integer;
    tASqr, tBSqr: Integer;
    StopX, StopY: Integer;
    XRadius, YRadius: Integer;
    XRadSqr, YRadSqr: Integer;
    x1, x2: Integer;
    y1, y2: Integer;
  begin
    (* Get width & Height of Operation *)
    dx:=(ARect.right-ARect.left)+1;
    dy:=(ARect.bottom-ARect.Top)+1;

    (* Get X & Y Radius *)
    XRadius := (dx-1) div 2;
    YRadius := (dy-1) div 2;

    (* Get Center_X & Center_Y *)
    cx1 := ARect.Left + XRadius;
    cy1 := ARect.Top  + YRadius;

    cx2 := cx1;
    cy2 := cy1;
    if not odd(dx) then inc(cx2);
    if not odd(dy) then inc(cy2);

    XRadSqr := sqr(XRadius);
    YRadSqr := sqr(YRadius);
    tASqr := 2*XRadSqr;
    tBSqr := 2*YRadSqr;

    X := XRadius;
    Y := 0;
    XChange := YRadSqr*(1-2*XRadius);
    YChange := XRadSqr;
    Err := 0;
    StopX := tBSqr*XRadius;
    StopY := 0;

    { 1st set of points }
    while (StopX >= StopY) do
    begin
      WriteClipped(cx1-x, cy1-y,FColorRaw);
      WriteClipped(cx2+x, cy1-y,FColorRaw);
      WriteClipped(cx1-x, cy2+y,FColorRaw);
      WriteClipped(cx2+x, cy2+y,FColorRaw);

      inc(y);
      inc(StopY, tASqr);
      inc(Err, YChange);
      inc(YChange, tASqr);
      if (2*Err+XChange > 0) then
      begin
        dec(x);
        dec(StopX, tBSqr);
        inc(Err, XChange);
        inc(XChange, tBSqr);
      end;
    end;

    y1 := y;
    y2 := y;
    x1 := x;
    x2 := x;

    { 2nd set of points }
    x := 0;
    y := YRadius;
    XChange := YRadSqr;
    YChange := XRadSqr*(1-2*YRadius);
    Err := 0;
    StopX := 0;
    StopY := tASqr*YRadius;
    while (StopX <= StopY) do
    begin
      WriteClipped(cx1-x, cy1-y,FColorRaw);
      WriteClipped(cx2+x, cy1-y,FColorRaw);
      WriteClipped(cx1-x, cy2+y,FColorRaw);
      WriteClipped(cx2+x, cy2+y,FColorRaw);

      inc(x);
      inc(StopX, tBSqr);
      inc(Err, XChange);
      inc(XChange, tBSqr);
      y2 := y; x2 := x;
      if (2*Err+YChange > 0) then
      begin
        dec(y);
        dec(StopY, tASqr);
        inc(Err, YChange);
        inc(YChange, tASqr);
      end;
    end;

    { fill the possible disconnection at the junction point }
    if YRadius > XRadius then
    begin
      dec(x);
      for y := y1 to y2-1 do
      begin
        WriteClipped(cx1-x, cy1-y,FColorRaw);
        WriteClipped(cx2+x, cy1-y,FColorRaw);
        WriteClipped(cx1-x, cy2+y,FColorRaw);
        WriteClipped(cx2+x, cy2+y,FColorRaw);
      end;
    end else
    begin
      dec(y);
      for x := x2 to x1 do
      begin
        WriteClipped(cx1-x, cy1-y,FColorRaw);
        WriteClipped(cx2+x, cy1-y,FColorRaw);
        WriteClipped(cx1-x, cy2+y,FColorRaw);
        WriteClipped(cx2+x, cy2+y,FColorRaw);
      end;
    end;
  end;

  procedure TPXRSurfaceCustom.Ellipse(Domain:TRect);
  Begin
    If not GetEmpty then
    FEllipseLUTEX[FPenStyle](Domain) else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.FillRect(Domain:TRect);
  Begin
    If not GetEmpty then
    Begin
      If  TPXRRect.IsValid(Domain)
      and TPXRRect.Intersect(Domain,FClipRect,Domain) then
      FFillRectLUT(Domain,self.FColorRaw);
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.FillRect(Domain:TRect;
            Const Value:TColor);
  var
    mData:  Longword;
  Begin
    If not GetEmpty then
    Begin
      If  TPXRRect.IsValid(Domain)
      and TPXRRect.Intersect(Domain,FClipRect,Domain) then
      Begin
        ColorToNativePixel(Value,mData);
        FFillRectLUT(Domain,mData);
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.Rectangle(Const Domain:TRect;
            Const Value:TColor);
  var
    mData:  Longword;
  Begin
    If not GetEmpty then
    Begin
      ColorToNativePixel(value,mData);

      (* check for single vertical line *)
      If  (Domain.left=Domain.right)
      and (Domain.bottom>=Domain.top) then
      FillCol(Domain.Left,Domain.Top,Domain.bottom-Domain.top+1,mData) else

      (* check for single hoizontal line *)
      if  (Domain.top=Domain.bottom)
      and (Domain.right>=Domain.left) then
      FillRow(Domain.left,Domain.top,Domain.right-Domain.left+1,mData) else

      if TPXRRect.IsValid(Domain) then
      Begin
        mData:=Color.ColorRef;
        Color.ColorRef:=value;
        Line(Domain.left,Domain.top,Domain.right,Domain.top);
        line(Domain.Right,Domain.top+1,Domain.right,Domain.bottom);
        line(Domain.Right-1,Domain.Bottom,Domain.left,Domain.Bottom);
        line(Domain.left,Domain.bottom-1,Domain.Left,Domain.top+1);
        Color.ColorRef:=mData;
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.Rectangle(Const Domain:TRect);
  Begin
    If not GetEmpty then
    Begin
      (* check for single vertical line *)
      If  (Domain.left=Domain.right)
      and (Domain.bottom>=Domain.top) then
      FillCol(Domain.Left,Domain.Top,Domain.bottom-Domain.top+1,FColorRaw) else

      (* check for single hoizontal line *)
      if  (Domain.top=Domain.bottom)
      and (Domain.right>=Domain.left) then
      FillRow(Domain.left,Domain.top,Domain.right-Domain.left+1,FColorRaw) else

      If  (Domain.left<Domain.right)
      and (Domain.top<Domain.Bottom) then
      Begin
        Line(Domain.left,Domain.top,Domain.right,Domain.top);
        line(Domain.Right,Domain.top+1,Domain.right,Domain.bottom);
        line(Domain.Right-1,Domain.Bottom,Domain.left,Domain.Bottom);
        line(Domain.left,Domain.bottom-1,Domain.Left,Domain.top+1);
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.Read(Const Col,Row:Integer;var aData);
  Begin
    if TPXRRect.IsWithin(Col,Row,FBounds) then
    FReadLut(col,row,aData);
  end;

  Procedure TPXRSurfaceCustom.WriteClipped
            (Const Col,Row:Integer);
  Begin
    If FCLipObj.Contains(col,row) then
    FWriteLUT(col,row,FColorRaw);
  end;

  Procedure TPXRSurfaceCustom.WriteClipped
            (Const Col,Row:Integer;Const pxData);
  Begin
    If FCLipObj.Contains(col,row) then
    FWriteLUT(col,row,pxData);
  end;

  procedure TPXRSurfaceCustom.WriteClipped
            (Const Col,Row:Integer;Const Color:TColor);
  var
    mTemp:Longword;
  Begin
    If FCLipObj.Contains(col,row) then
    Begin
      ColorToNativePixel(Color,mTemp);
      FWriteLUT(col,row,mTemp);
    end;
  end;

  Procedure TPXRSurfaceCustom.LineH(Col,Row:Integer;NumberOfColumns:Integer);
  Begin
    If not GetEmpty then
    FillRow(row,col,NumberOfColumns,FColorRaw) else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.LineV(Col,Row:Integer;NumberOfRows:Integer);
  Begin
    If not GetEmpty then
    FillCol(col,row,NumberOfRows,FColorRaw) else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.LineTo(Const Col,Row:Integer);
  Begin
    Line(FCursor.X,FCursor.Y,Col,Row);
  end;

  Procedure TPXRSurfaceCustom.Line(Left,Top,Right,Bottom:Integer);
  var
    ix, iy, pp, cp: Integer;
    dr,du,i,FPixels: Integer;
  Begin
    If not GetEmpty then
    Begin
      (* set new cursor position *)
      FCursor.x:=Right;
      FCursor.y:=Bottom;

      if PXR_LineClip(FClipRect,Left,Top,Right,Bottom) then
      Begin
        (* vertical? *)
        If Left=Right then
        Begin
          If Bottom<Top then
          PXR_SwapInt(Bottom,Top);
          FPixels:=Bottom - Top + 1;
          FillCol(left,top,FPixels,FColorRaw);
        end else

        (* horizontal? *)
        if top=Bottom then
        Begin
          If Right<Left then
          PXR_SwapInt(Right,Left);
          FPixels:=Right-Left + 1;
          FillRow(top,left,FPixels,FColorRaw);
        end else
        Begin
          (* odd line *)
          dec(right,left);
          dec(bottom,top);

          if right>0 then
          ix := +1 else
          ix := -1; cp := -1;

          if bottom>0 then
          iy := +1 else
          iy := -1;

          right:=PXR_Positive(right);
          bottom:=PXR_Positive(bottom);

          if right>=bottom then
          begin
            dr:= bottom shl 1;
            du:= dr - right shl 1;
            pp := dr-right;
            for i := 0 to right do
            begin
              FWriteLUT(left,top,FColorRaw);
              inc(left,ix);
              if pp > cp then
              begin
                inc(top,iy);
                inc(pp,du);
              end else
              inc(pp,dr);
            end;
          end else
          begin
            dr := right shl 1;
            du := dr - bottom shl 1;
            pp := dr-bottom;
            for i := 0 to bottom do
            begin
              FWriteLUT(left,top,FColorRaw);
              inc(top,iy);
              if pp > cp then
              begin
                inc(left,ix);
                inc(pp,du);
              end else
              inc(pp,dr);
            end;
          end;
        end;
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.Bezier(Const Domain:TPXRPointArray);
  var
    maxsegment: Integer;
    Count:      Integer;
    FCtrlCount: Integer;
    z:          Integer;
    FData:      TPXRPointArray;
    X, Y:       array[0..3] of Integer;
    SqLimit:    Single;

    procedure BezierPoint(U:Single; var PosX, PosY:Single);
    var
      U2, U3: single;
    begin
      U2 := U * U;
      U3 := U2 * U;
      PosX := X[3] * U3 + X[2] * U2 + X[1] * U + X[0];
      PosY := Y[3] * U3 + Y[2] * U2 + Y[1] * U + Y[0];
    end;

    procedure DrawOrDivide(A,B:Single);
    var
      M,PAX,PAY,PBX,PBY,PMX,PMY,
      SqDistL,SqDistR,SqDistT: Single;
    begin
      M := (A + B) / 2;
      BezierPoint(A, PAX, PAY);
      BezierPoint(M, PMX, PMY);
      BezierPoint(B, PBX, PBY);

      SqDistL := sqr(PMX - PAX) + sqr(PMY - PAY); // Left side dist
      SqDistR := sqr(PBX - PMX) + sqr(PBY - PMY); // Right side dist
      SqDistT := sqr(PBX - PAX) + sqr(PBY - PAY); // Total dist
      if  (SqDistL < SqLimit) and
          (SqDistR < SqLimit) and
          (SqDistT < SqLimit) then
      begin
        if count > length(FData) - 1 then
        setlength(FData, length(FData) + 100);
        FData[count].X:=round(PBX);
        FData[count].Y:=round(PBY);
        inc(Count);
      end else
      begin
        DrawOrDivide(A, M);
        DrawOrDivide(M, B);
      end;
    end;
    
  Begin
    If not GetEmpty then
    Begin
      FCtrlCount:=Length(Domain);
      If FCtrlCount=4 then
      Begin
        MaxSegment:=64;

        Setlength(FData, 100);
        FData[0] := Domain[0];
        Count := 1;

        SqLimit := sqr(maxsegment);
        if SqLimit = 0 then
        Sqlimit := 1;

        X[3]:=-1* Domain[0].X + 3  * Domain[1].X + -3 *
        Domain[2].X + 1 * Domain[3].X;
        X[2]:=3 * Domain[0].X + -6 * Domain[1].X + 3  * Domain[2].X;
        X[1]:=-3* Domain[0].X + 3  * Domain[1].X;
        X[0]:=1 * Domain[0].X;

        Y[3]:=-1* Domain[0].Y + 3 * Domain[1].Y + -3 * Domain[2].Y + 1
        * Domain[3].Y;
        Y[2]:=3 * Domain[0].Y + -6 * Domain[1].Y + 3 * Domain[2].Y;
        Y[1]:=-3* Domain[0].Y + 3 * Domain[1].Y;
        Y[0]:=1 * Domain[0].Y;

        DrawOrDivide(0, 1);

        Setlength(FData, count + 1);
        FData[count] := Domain[3];

        MoveTo(FData[0].x,FData[0].y);
        for z:=low(FData)+1 to high(FData) do
        LineTo(FData[z].x,FData[z].y);

      end else
      Raise EPXRSurfaceCustom.Create('Invalid Bezier points');
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.FillRect08(Const Region:TRect;Const inData);
  var
    FLongs:       Integer;
    cols,rows:    Integer;
    FRoot:        PByte;
  Begin
    (* Break it down into cols & rows *)
    Cols:=Region.Right + 1;
    dec(Cols,Region.Left);

    rows:=Region.Bottom + 1;
    dec(rows,Region.Top);

    FLongs:=Rows shr 3;

    FRoot:=GetPixelAddr(Region.left,Region.top);
    While FLongs>0 do
    Begin
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillByte(FRoot,Cols,Byte(inData)); inc(FRoot,FPitch);
      dec(FLongs);
    end;

    Case Rows mod 8 of
    1:  TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
    2:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    3:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    4:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    5:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    6:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    7:  Begin
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));inc(FRoot,FPitch);
          TBRBuffer.FillByte(FRoot,Cols,Byte(inData));
        end;
    end;
  end;

  Procedure TPXRSurfaceCustom.FillRect16(Const Region:TRect;Const inData);
  var
    FLongs:       Integer;
    cols,rows:    Integer;
    FRoot:        PByte;
  Begin
    (* Break it down into cols & rows *)
    Cols:=Region.Right + 1;
    dec(Cols,Region.Left);

    rows:=Region.Bottom + 1;
    dec(rows,Region.Top);

    FLongs:=Rows shr 3;

    FRoot:=GetPixelAddr(Region.left,Region.top);
    While FLongs>0 do
    Begin
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData)); inc(FRoot,FPitch);
      dec(FLongs);
    end;

    Case Rows mod 8 of
    1:  TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
    2:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    3:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    4:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    5:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    6:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    7:  Begin
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));inc(FRoot,FPitch);
        TBRBuffer.FillWord(system.PWord(FRoot),Cols,word(inData));
        end;
    end;
  end;

  procedure TPXRSurfaceCustom.FillRect24(Const Region:TRect;Const inData);
  var
    FLongs:       Integer;
    cols,rows:    Integer;
    FRoot:        PByte;
  Begin
    (* Break it down into cols & rows *)
    Cols:=Region.Right + 1;
    dec(Cols,Region.Left);

    rows:=Region.Bottom + 1;
    dec(rows,Region.Top);

    FLongs:=Rows shr 3;

    FRoot:=GetPixelAddr(Region.left,Region.top);
    While FLongs>0 do
    Begin
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
      inc(FRoot,FPitch);
      dec(FLongs);
    end;

    Case Rows mod 8 of
    1:  TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
    2:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    3:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    4:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    5:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    6:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    7:  Begin
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        inc(FRoot,FPitch);
        TBRBuffer.FillTriple(PBRTripleByte(FRoot),Cols,TBRTripleByte(inData));
        end;
    end;
  end;

  Procedure TPXRSurfaceCustom.FillRect32(Const Region:TRect;Const inData);
  var
    FLongs,
    cols,rows:  Integer;
    FRoot:      system.PByte;
  Begin
    (* Break it down into cols & rows *)
    Cols:=Region.Right + 1;
    dec(Cols,Region.Left);

    rows:=Region.Bottom + 1;
    dec(rows,Region.Top);

    FLongs:=Rows shr 3;

    FRoot:=PixelAddr(Region.left,Region.top);
    While FLongs>0 do
    Begin
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData)); inc(FRoot,FPitch);
      dec(FLongs);
    end;

    Case Rows mod 8 of
    1:  TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
    2:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    3:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    4:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    5:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    6:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    7:  Begin
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));inc(FRoot,FPitch);
        TBRBuffer.FillLong(PLongword(FRoot),Cols,Longword(inData));
        end;
    end;
  end;

  procedure TPXRSurfaceCustom.FillRectWithWriter(Const Region:TRect;
            Const inData);
  var
    y:        Integer;
    wd,hd:    Integer;
    FLongs:   Integer;
    FTemp:    Longword;
  Begin
    y:=Region.Top;
    wd:=Region.right - Region.left + 1;
    hd:=Region.bottom - Region.top + 1;

    FTemp:=Longword(inData);

    FLongs:=hd shr 3;
    while FLongs>0 do
    Begin
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      FillRow(y,Region.left,wd,FTemp); inc(y);
      dec(FLongs);
    end;

    Case hd mod 8 of
    1:  FillRow(y,Region.left,wd,FTemp);
    2:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
    3:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
    4:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
    5:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
    6:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
    7:  Begin
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp); inc(y);
          FillRow(y,Region.left,wd,FTemp);
        end;
      end;
  end;

  Procedure TPXRSurfaceCustom.MoveTo(Left,Top:Integer);
  Begin
    FCursor.X := left;
    FCursor.Y := top;
  end;

  Procedure TPXRSurfaceCustom.SetCursor(Value:TPoint);
  Begin
    FCursor:=Value;
  End;

  Function TPXRSurfaceCustom.GetPixel(Const col,Row:Integer):TColor;
  var
    FData:  PByte;
  Begin
    (* Checking is done by WithinBoundsRect for us *)
    If FCLipObj.Contains(col,row) then
    Begin
      FData:=GetPixelAddr(Col,Row);
      NativePixelToColor(FData^,Result);
    end;
  end;

  Procedure TPXRSurfaceCustom.SetPixel(Const Col,Row:Integer;Value:TColor);
  var
    mTemp:    Longword;
  Begin
    (* Checking is done by WithinClipRect for us *)
    If FCLipObj.Contains(col,row) then
    Begin
      (* Convert TColor to native *)
      ColorToNativePixel(Value,mTemp);

      (* Write pixel data *)
      FWriteLUT(Col,Row,mTemp);
    end;
  end;

  Function TPXRSurfaceCustom.GetTransparentColorValue:TColor;
  Begin
    result:=FTransColor;
  end;

  Function TPXRSurfaceCustom.GetPenAlpha:Byte;
  Begin
    result:=FPenAlpha;
  end;

  Procedure TPXRSurfaceCustom.SetPenAlpha(Value:Byte);
  Begin
    FPenAlpha:=Value;
  end;

  Procedure TPXRSurfaceCustom.SetTransparentColorValue(Value:TColor);
  Begin
    if Value<>FTransColor then
    Begin
      FTransColor:=Value;
      ColorToNativePixel(Value,FTransRaw);
    end;
  end;

  Procedure TPXRSurfaceCustom.SetTransparent(Value:Boolean);
  Begin
    FTransparent:=Value;
  end;

  Function TPXRSurfaceCustom.GetColorValue:TColor;
  Begin
    result:=FColor;
  end;

  Procedure TPXRSurfaceCustom.SetColorValue(Value:TColor);
  Begin
    If Value<>FColor then
    Begin
      FColor:=Value;
      ColorToNativePixel(Value,FColorRaw);
    end;
  end;

  Procedure TPXRSurfaceCustom.NativePixelToColor(Const Data;var Value:TColor);
  Begin
    Case FFormat of
    pf8Bit:
      Begin
        If FPalette<>NIL then
        Value:=FPalette.Items[Byte(data)] else
        value:=clNone;
      end;
    pf15Bit:  Value:=TPXRPaletteColor.ColorFrom15(Data);
    pf16Bit:  Value:=TPXRPaletteColor.ColorFrom16(Data);
    pf24Bit:  Value:=TPXRPaletteColor.ColorFrom24(Data);
    pf32Bit:  Value:=TPXRPaletteColor.ColorFrom32(Data)
   end;
  end;

  Procedure TPXRSurfaceCustom.FillRow(Const Row:Integer;Col,inCount:Integer;
            var inData);
  var
    FLongs:   Integer;
    FSingles: Integer;
  Begin
    If  (inCount>0)
    and FClipObj.ContainsRow(Row) then
    Begin

      (* Clip left *)
      If Col<FClipRect.left then
      Begin
        dec(inCount,PXR_Diff(Col,FClipRect.left - 1));
        Col:=FClipRect.left; //** FIXED 01.11.07
        if inCount<1 then
        exit;
      end;

      (* clip right *)
      If Col+inCount-1>FClipRect.Right then
      Begin
        dec(inCount,PXR_Diff( (Col + inCount) -1,FClipRect.right));
        if inCount<1 then
        exit;
      end;

      FLongs:=inCount shr 3;
      FSingles:=inCount mod 8;

      inc(inCount,Col-1);
      While FLongs>0 do
      Begin
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        FWriteLUT(incount,row,inData); dec(incount);
        dec(FLongs);
      end;

      while FSingles>0 do
      Begin
        FWriteLUT(incount,row,inData); dec(incount);
        dec(FSingles);
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.FillCol(Const Col:Integer;
            Row,inCount:Integer;var inData);
  var
    FLongs:   Integer;
    FSingles: Integer;
    FTemp:    Integer;
    FBottom:  Integer;
    dst:      PByte;
  Begin
    If  (inCount>0)
    and FClipObj.ContainsColumn(col)
    and (row<=FClipObj.bottom) then
    Begin
      (* Clip top *)
      If Row<FClipRect.top then
      Begin
        FTemp:=PXR_Diff(Row,FClipRect.top);
        dec(inCount,FTemp);
        Row:=FClipRect.top;
        if inCount<1 then
        exit;
      end;

      (* clip bottom *)
      FBottom:=((Row + inCount)-1);
      If FBottom > FClipRect.bottom then
      Begin
        FTemp:=PXR_Diff(FBottom,FClipRect.bottom);
        dec(inCount,FTemp);
        if inCount<1 then
        exit;
      end;


      FLongs:=inCount shr 3;
      FSingles:=inCount mod 8;

      inc(inCount,row-1);
      While FLongs>0 do
      Begin
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        FWriteLUT(col,inCount,inData); dec(incount);
        dec(FLongs);
      end;

      while FSingles>0 do
      Begin
        FWriteLUT(col,inCount,inData); dec(incount);
        dec(FSingles);
      end;

    end;
  end;

  Procedure TPXRSurfaceCustom.ColorToNativePixel(Value:TColor;var Data);
  Begin
    case FFormat of
    pf8Bit:   TPXRPaletteColor.ColorTo08(Value,FPalette,Data);
    pf15Bit:  TPXRPaletteColor.ColorTo15(Value,Data);
    pf16Bit:  TPXRPaletteColor.ColorTo16(Value,Data);
    pf24Bit:  TPXRPaletteColor.ColorTo24(Value,Data);
    pf32Bit:  TPXRPaletteColor.ColorTo32(Value,Data);
    end;
  end;

  Procedure TPXRSurfaceCustom.AdjustToBoundsRect(var Domain:TRect);
  Begin
    If not GetEmpty then
    TPXRRect.ClipTo(Domain,FBounds) else
    Domain:=TPXRRect.NullRect;
  end;

  Function TPXRSurfaceCustom.GetStrideAlign(Const Value,ElementSize:Integer;
           Const AlignSize:Integer=4):Integer;
  Begin
    Result:=Value * ElementSize;
    If (Result mod AlignSize)>0 then
    result:=( (Result + AlignSize) - (Result mod AlignSize) );
  end;

  Procedure TPXRSurfaceCustom.Release;
  Begin
    If not GetEmpty then
    Begin
      FPenColor.ColorRef:=clWhite;
      FClipObj.Clear;
      
      try
        ReleaseSurface;
      finally
        If FPalette<>NIL then
        FreeAndNIL(FPalette);
        FWidth:=0;
        FHeight:=0;
        FFormat:=pfDevice;
        FBounds:=TPXRRect.NullRect;
        FBitsPP:=0;
        FBytesPP:=0;
        FPitch:=0;
        FColor:=0;
        FColorRaw:=0;

        FReadLUT:=NIL;
        FWriteLUT:=NIL;
      end;
    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_NotAllocated);
  end;

  Procedure TPXRSurfaceCustom.Alloc(aWidth,aHeight:Integer;aFormat:TPixelFormat);
  Begin
    (* Release if allocated *)
    If not GetEmpty then
    Release;

    (* Create default palette for 8bit [if none set] *)
    if aFormat=pf8Bit then
    Begin
      if FPalette=NIL then
      SetPalette(TPXRPaletteNetScape.Create);
    end;

    (* Call abstract method to allocate. Parameters are VAR, so we must not
       ignore the fact that the implementor might set restrictions *)
    AllocSurface(aWidth,aHeight,aFormat,FPitch,FDataSize);

    (* Keep values and initialize *)
    FWidth:=aWidth;
    FHeight:=aHeight;
    FFormat:=aFormat;
    FBounds:=Rect(0,0,aWidth-1,aHeight-1);
    FBitsPP:=GetPerPixelBits(aFormat);
    FBytesPP:=GetPerPixelBytes(aFormat);
    FCursor.X:=0;
    FCursor.Y:=0;
    FPenStyle:=stOutline;
    FDrawMode:=dmCopy;
    FPenAlpha:=255;

    FClipObj.SetRect(FBounds);

    (* Setup pixel reader and writer *)
    FReadLUT:=FReadLUTEX[FFormat];
    FWriteLUT:=FWriteLUTEX[FFormat,FDrawMode];
    FFillRectLUT:=FFillRectLUTEX[FFormat,FDrawMode];
  end;

  function TPXRSurfaceCustom.getPenStyle:TPXRPenStyle;
  Begin
    result:=FPenStyle;
  end;

  Procedure TPXRSurfaceCustom.SetPenStyle(Value:TPXRPenStyle);
  Begin
    if value<>FPenStyle then
    Begin
      FPenStyle:=Value;
    end;
  end;

  Function TPXRSurfaceCustom.GetDrawMode:TPXRDrawMode;
  Begin
    result:=FDrawMode;
  end;

  Procedure TPXRSurfaceCustom.SetDrawMode(Value:TPXRDrawMode);
  var
    FOldMode: TPXRDrawMode;
  Begin
    If Value<>FDrawMode then
    Begin
      (* Keep old mode & set new *)
      FOldMode:=FDrawMode;
      FDrawMode:=Value;

      (* Set correct pixelwriter *)
      FWriteLUT:=FWriteLUTEX[FFormat,FDrawMode];
      FFillRectLUT:=FFillRectLUTEX[FFormat,FDrawMode];

      (* Notify user *)
      if assigned(FOnDrawModeAltered) then
      FOnDrawModeAltered(self,FOldMode,FDrawMode);
    end;
  end;

  Function TPXRSurfaceCustom.GetPerPixelBits(aFormat:TPixelFormat):Integer;
  Begin
    if (aFormat in [pf8bit..pf32bit]) then
    result:=PerPixel_Bits[aFormat] else
    result:=0;
  end;

  Function TPXRSurfaceCustom.GetPerPixelBytes(aFormat:TPixelFormat):Integer;
  Begin
    if (aFormat in [pf8bit..pf32bit]) then
    result:=PerPixel_Bytes[aFormat] else
    result:=0;
  end;

  (* This proc is private and does not check coordinates! *)
  Function TPXRSurfaceCustom.GetPixelAddr(Const Col,Row:Integer):PByte;
  Begin
    result:=GetScanLine(Row);
    inc(Result,Col * FBytesPP);
  end;

  (* This proc is public and hence it uses checking *)
  Function TPXRSurfaceCustom.PixelAddr(Const Col,Row:Integer):PByte;
  Begin
    (* Checking is done by WithinBoundsRect for us *)
    if TPXRRect.IsWithin(Col,Row,FBounds) then
    Begin
      result:=GetScanLine(Row);
      inc(Result,Col * FBytesPP);
    end else
    result:=NIL;
  end;

    (* pixel decoders *)           
  Procedure TPXRSurfaceCustom.Decode08(const thispixel;var R,G,B:Byte);
  Begin
    FPalette.ExportRGB(Byte(thispixel),R,G,B);
  end;

  Procedure TPXRSurfaceCustom.Decode15(const thispixel;var R,G,B:Byte);
  Begin
    TPXRColorCustom.RGBFrom15(thispixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Decode16(const thispixel;var R,G,B:Byte);
  Begin
    TPXRColorCustom.RGBFrom16(thispixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Decode24(const thispixel;var R,G,B:Byte);
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Decode32(const thispixel;var R,G,B:Byte);
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Encode08(Const R,G,B:Byte; var thatpixel);
  Begin
    Byte(thatpixel):=FPalette.Match(r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Encode15(Const R,G,B:Byte; var thatpixel);
  Begin
    TPXRColorCustom.RGBTo15(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Encode16(Const R,G,B:Byte; var thatpixel);
  Begin
    TPXRColorCustom.RGBTo16(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Encode24(Const R,G,B:Byte; var thatpixel);
  Begin
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.Encode32(Const R,G,B:Byte; var thatpixel);
  Begin
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv08x08(const thispixel;var thatpixel);
  Begin
    Byte(thatPixel):=byte(thispixel);
  end;

  Procedure TPXRSurfaceCustom.PxConv08x15(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    FCopyPal.ExportRGB(Byte(thispixel),r,g,b);
    TPXRColorCustom.RGBTo15(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv08x16(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    FCopyPal.ExportRGB(Byte(thispixel),r,g,b);
    TPXRColorCustom.RGBTo16(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv08x24(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    FCopyPal.ExportRGB(Byte(thispixel),r,g,b);
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv08x32(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    FCopyPal.ExportRGB(Byte(thispixel),r,g,b);
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv15x08(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom15(thispixel,r,g,b);
    Byte(thatpixel):=FCopyPal.Match(R,G,B);
  end;

  Procedure TPXRSurfaceCustom.PxConv15x15(const thispixel;var thatpixel);
  Begin
    word(thatpixel):=word(thispixel);
  end;

  Procedure TPXRSurfaceCustom.PxConv15x16(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom15(thispixel,r,g,b);
    TPXRColorCustom.RGBTo16(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv15x24(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom15(thispixel,r,g,b);
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv15x32(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom15(thispixel,r,g,b);
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv16x08(const thispixel;var thatpixel);
  var
    r,g,b:Byte;
  Begin
    TPXRColorCustom.RGBFrom16(thispixel,r,g,b);
    Byte(thatpixel):=FCopyPal.Match(R,G,B);
  end;

  Procedure TPXRSurfaceCustom.PxConv16x15(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom16(thispixel,r,g,b);
    TPXRColorCustom.RGBTo15(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv16x16(const thispixel;var thatpixel);
  Begin
    word(thatpixel):=word(thispixel);
  end;

  Procedure TPXRSurfaceCustom.PxConv16x24(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom16(thispixel,r,g,b);
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv16x32(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom16(thispixel,r,g,b);
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv24x08(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv24x15(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
    TPXRColorCustom.RGBTo15(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv24x16(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
    TPXRColorCustom.RGBTo16(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv24x24(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv24x32(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom24(thispixel,r,g,b);
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv32x08(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
    Byte(thatpixel):=FCopyPal.Match(r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv32x15(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
    TPXRColorCustom.RGBTo15(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv32x16(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
    TPXRColorCustom.RGBTo16(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv32x24(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
    TPXRColorCustom.RGBTo24(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.PxConv32x32(const thispixel;var thatpixel);
  var
    r,g,b:  Byte;
  Begin
    TPXRColorCustom.RGBFrom32(thispixel,r,g,b);
    TPXRColorCustom.RGBTo32(thatpixel,r,g,b);
  end;

  Procedure TPXRSurfaceCustom.CPY8bitTo8Bit;
  var
    src:  PByte;
    dst:  PByte;
    x:    Integer;
  Begin
    src:=FCopySrc;
    dst:=FCopyDst;
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin dst^:=src^; inc(src); inc(dst); end;
  end;

  Procedure TPXRSurfaceCustom.CPY8BitTo15Bit;
  var
    src:    PByte;
    dst:    PWord;
    x:      Integer;
  Begin
    src:=FCopySrc;
    dst:=PWord(FCopyDst);
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin
      ColorToNativePixel(FCopyPal.Items[src^],dst^);
      inc(src); inc(dst);
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY8BitTo16Bit;
  var
    src:    PByte;
    dst:    PWord;
    x:      Integer;
  Begin
    src:=FCopySrc;
    dst:=PWord(FCopyDst);
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin
      ColorToNativePixel(FCopyPal.Items[src^],dst^);
      inc(src); inc(dst);
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY8BitTo24Bit;
  var
    src:    PByte;
    dst:    PRGBTriple;
    x:      Integer;
  Begin
    src:=FCopySrc;
    dst:=PRGBTriple(FCopyDst);
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin
      ColorToNativePixel(FCopyPal.Items[src^],dst^);
      inc(src);
      inc(dst);
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY8BitTo32Bit;
  var
    src:    PByte;
    dst:    PRGBQuad;
    x:      Integer;
  Begin
    src:=FCopySrc;
    dst:=PRGBQuad(FCopyDst);
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin
      ColorToNativePixel(FCopyPal.Items[src^],dst^);
      inc(src); inc(dst);
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY15bitTo8Bit;
  var
    src:    PWord;
    dst:    PByte;
    r,g,b:  Byte;
    x:      Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=FCopyDst;
    for x:=FCopydstRect.left to FCopydstRect.right do
    Begin
      r:=((src^ and $7C00) shr 10) shl 3;
      g:=((src^ and $03E0) shr 5) shl 3;
      b:=(src^ and $001F) shl 3;
      dst^:=FPalette.Match(R,G,B);
      inc(src);
      inc(dst);
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY15BitTo15Bit;
  var
    src:  PWord;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          dst^:=src^; inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=src^; inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY15BitTo16Bit;
  var
    src:  PWord;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          dst^:=(src^ and $1F) or ((src^ and $7FE0) shl 1);
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=(src^ and $1F) or ((src^ and $7FE0) shl 1);
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY15BitTo24Bit;
  var
    src:  PWord;
    dst:  PRGBTriple;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PRGBTriple(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          Begin
            dst^.rgbtRed:=((src^ and $7C00) shr 10) shl 3;
            dst^.rgbtGreen:=((src^ and $03E0) shr 5) shl 3;
            dst^.rgbtBlue:=(src^ and $001F) shl 3;
          end;
          inc(dst); inc(src);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbtRed:=((src^ and $7C00) shr 10) shl 3;
          dst^.rgbtGreen:=((src^ and $03E0) shr 5) shl 3;
          dst^.rgbtBlue:=(src^ and $001F) shl 3;
          inc(dst); inc(src);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY15BitTo32Bit;
  var
    src:  PWord;
    dst:  PRGBQuad;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PRGBQuad(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          Begin
            dst^.rgbRed:=((src^ and $7C00) shr 10) shl 3;
            dst^.rgbGreen:=((src^ and $03E0) shr 5) shl 3;
            dst^.rgbBlue:=(src^ and $001F) shl 3;
          end;
          inc(dst); inc(src);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbRed:=((src^ and $7C00) shr 10) shl 3;
          dst^.rgbGreen:=((src^ and $03E0) shr 5) shl 3;
          dst^.rgbBlue:=(src^ and $001F) shl 3;
          inc(dst); inc(src);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY16bitTo8Bit;
  var
    src:    PWord;
    dst:    PByte;
    r,g,b:  Byte;
    x:      Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=FCopyDst;
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          Begin
            r:=Byte(((src^ and $F800) shr 11) shl 3);
            g:=Byte(((src^ and $07E0) shr 5) shl 2);
            b:=Byte((src^ and $001F) shl 3);
            dst^:=FPalette.Match(R,G,B);
          end;
          inc(dst); inc(src);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          r:=Byte(((src^ and $F800) shr 11) shl 3);
          g:=Byte(((src^ and $07E0) shr 5) shl 2);
          b:=Byte((src^ and $001F) shl 3);
          dst^:=FPalette.Match(R,G,B);
          inc(dst); inc(src);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY16BitTo15Bit;
  var
    src:  PWord;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          dst^:=(src^ and $1F) or ((src^ and $FFC0) shr 1);
          inc(src);inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=(src^ and $1F) or ((src^ and $FFC0) shr 1);
          inc(src);inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY16BitTo16Bit;
  var
    src:  PWord;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          dst^:=src^; inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=src^; inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY16BitTo24Bit;
  var
    src:  PWord;
    dst:  PRGBTriple;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PRGBTriple(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          Begin
            dst^.rgbtRed:=(((src^ and $F800) shr 11) shl 3);
            dst^.rgbtGreen:=byte(((src^ and $07E0) shr 5) shl 2);
            dst^.rgbtBlue:=byte((src^ and $001F) shl 3);
          end;
          inc(dst); inc(src);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbtRed:=(((src^ and $F800) shr 11) shl 3);
          dst^.rgbtGreen:=byte(((src^ and $07E0) shr 5) shl 2);
          dst^.rgbtBlue:=byte((src^ and $001F) shl 3);
          inc(dst); inc(src);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY16BitTo32Bit;
  var
    src:  PWord;
    dst:  PRGBQuad;
    x:    Integer;
  Begin
    src:=PWord(FCopySrc);
    dst:=PRGBQuad(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If src^<>Word(FCopyKey) then
          Begin
            dst^.rgbRed:=(((src^ and $F800) shr 11) shl 3);
            dst^.rgbGreen:=byte(((src^ and $07E0) shr 5) shl 2);
            dst^.rgbBlue:=byte((src^ and $001F) shl 3);
          end;
          inc(dst); inc(src);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbRed:=(((src^ and $F800) shr 11) shl 3);
          dst^.rgbGreen:=byte(((src^ and $07E0) shr 5) shl 2);
          dst^.rgbBlue:=byte((src^ and $001F) shl 3);
          inc(dst); inc(src);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY24bitTo8Bit;
  var
    src:  PRGBTriple;
    dst:  PByte;
    x:    Integer;
    FTP:  PRGBTriple;
  Begin
    src:=PRGBTriple(FCopySrc);
    dst:=FCopyDst;
    Case FCopyTrans of
    True:
      Begin
        FTP:=PRGBTriple(@FCopyKey);
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=FPalette.Match(src^.rgbtRed,src^.rgbtGreen,src^.rgbtBlue);
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=FPalette.Match(src^.rgbtRed,src^.rgbtGreen,src^.rgbtBlue);
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY24BitTo15Bit;
  var
    src:  PRGBTriple;
    dst:  PWord;
    x:    Integer;
    FTP:  PRGBTriple;
  Begin
    src:=PRGBTriple(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        FTP:=PRGBTriple(@FCopyKey);
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=Word(src^.rgbtRed shr 3
          shl 10 or src^.rgbtGreen shr 3 shl 5
          or src^.rgbtBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=Word(src^.rgbtRed shr 3 shl 10
          or src^.rgbtGreen shr 3 shl 5
          or src^.rgbtBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY24BitTo16Bit;
  var
    src:      PRGBTriple;
    dst:      PWord;
    FTP:      PRGBTriple;
    FLongs:   Integer;
    FSingles: Integer;
  Begin
    src:=PRGBTriple(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        FTP:=PRGBTriple(@FCopyKey);
        FLongs:=FCopyCnt shr 3;
        While FLongs>0 do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);
          dec(FLongs);
        end;

        FSingles:=FCopyCnt mod 8;
        While FSingles>0 do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);
          dec(FSingles);
        end;
      end;
    False:
      Begin
        FLongs:=FCopyCnt shr 3;
        While FLongs>0 do
        Begin
          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dst^:=(src^.rgbtRed shr 3) shl 11
          or (src^.rgbtGreen shr 2) shl 5
          or (src^.rgbtBlue shr 3); inc(src);inc(dst);

          dec(FLongs);
        end;
        Case FCopyCnt mod 8 of
        1:  dst^:=(src^.rgbtRed shr 3) shl 11
            or (src^.rgbtGreen shr 2) shl 5
            or (src^.rgbtBlue shr 3);
        2:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            end;
        3:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            End;
        4:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            end;
        5:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            end;
        6:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            end;
        7:  Begin
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3); inc(src);inc(dst);
              dst^:=(src^.rgbtRed shr 3) shl 11
              or (src^.rgbtGreen shr 2) shl 5
              or (src^.rgbtBlue shr 3);
            end;
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY24BitTo24Bit;
  var
    src:    PRGBTriple;
    dst:    PRGBTriple;
    x:      Integer;
    FTP:    PRGBTriple;
    FLongs: Integer;
  Begin
    src:=PRGBTriple(FCopySrc);
    dst:=PRGBTriple(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        FTP:=PRGBTriple(@FCopyKey);
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          dst^:=src^; inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        FLongs:=FCopyCnt shr 4;
        While FLongs>0 do
        Begin
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dst^:=src^; inc(src); inc(dst);
          dec(FLongs);
        end;

        Case FCopyCnt mod 16 of
        1:  dst^:=src^;
        2:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        3:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            End;
        4:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        5:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        6:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        7:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        8:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        9:  Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        10: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        11: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        12: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        13: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        14: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        15: Begin
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^; inc(src); inc(dst);
              dst^:=src^;
            end;
        end;

      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY24BitTo32Bit;
  var
    src:  PRGBTriple;
    dst:  PRGBQuad;
    x:    Integer;
    FTP:  PRGBTriple;
  Begin
    src:=PRGBTriple(FCopySrc);
    dst:=PRGBQuad(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        FTP:=PRGBTriple(@FCopyKey);
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          If  (src^.rgbtRed<>FTP.rgbtRed)
          and (src^.rgbtGreen<>FTP^.rgbtGreen)
          and (src^.rgbtBlue<>FTP^.rgbtBlue) then
          Begin
            dst^.rgbRed:=src^.rgbtRed;
            dst^.rgbGreen:=src^.rgbtGreen;
            dst^.rgbBlue:=src^.rgbtBlue;
          end;
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbRed:=src^.rgbtRed;
          dst^.rgbGreen:=src^.rgbtGreen;
          dst^.rgbBlue:=src^.rgbtBlue;
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY32bitTo8Bit;
  var
    src:  PRGBQuad;
    dst:  PByte;
    x:    Integer;
  Begin
    src:=PRGBQuad(FCopySrc);
    dst:=FCopyDst;
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=FPalette.Match(src^.rgbRed,src^.rgbGreen,src^.rgbBlue);
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=FPalette.Match(src^.rgbRed,src^.rgbGreen,src^.rgbBlue);
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY32BitTo15Bit;
  var
    src:  PRGBQuad;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PRGBQuad(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=Word(src^.rgbRed shr 3 shl 10
          or src^.rgbGreen shr 3 shl 5 or src^.rgbBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=Word(src^.rgbRed shr 3 shl 10
          or src^.rgbGreen shr 3 shl 5
          or src^.rgbBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY32BitTo16Bit;
  var
    src:  PRGBQuad;
    dst:  PWord;
    x:    Integer;
  Begin
    src:=PRGBQuad(FCopySrc);
    dst:=PWord(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=(src^.rgbRed shr 3) shl 11
          or (src^.rgbGreen shr 2) shl 5
          or (src^.rgbBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=(src^.rgbRed shr 3) shl 11
          or (src^.rgbGreen shr 2) shl 5
          or (src^.rgbBlue shr 3);
          inc(src);inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY32BitTo24Bit;
  var
    src:  PRGBQuad;
    dst:  PRGBTriple;
    x:    Integer;
  Begin
    src:=PRGBQuad(FCopySrc);
    dst:=PRGBTriple(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbtRed:=src^.rgbRed;
          dst^.rgbtGreen:=src^.rgbGreen;
          dst^.rgbtBlue:=src^.rgbBlue;
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^.rgbtRed:=src^.rgbRed;
          dst^.rgbtGreen:=src^.rgbGreen;
          dst^.rgbtBlue:=src^.rgbBlue;
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  Procedure TPXRSurfaceCustom.CPY32BitTo32Bit;
  var
    src:  PLongword;
    dst:  PLongword;
    x:    Integer;
  Begin
    src:=PLongword(FCopySrc);
    dst:=PLongword(FCopyDst);
    Case FCopyTrans of
    True:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=src^;
          inc(src); inc(dst);
        end;
      end;
    False:
      Begin
        for x:=FCopydstRect.left to FCopydstRect.right do
        Begin
          dst^:=src^;
          inc(src); inc(dst);
        end;
      end;
    end;
  end;

  //###########################################################################
  //  TPXRRect
  //###########################################################################

  Constructor TPXRRect.Create;
  Begin
    inherited Create;
    FRect:=PXR_NULLRect;
  end;

  Procedure TPXRRect.Clip(var Value:TRect);
  Begin
    if Value.Left < FRect.left then value.left:=FRect.left;
    if value.top < FRect.top then value.top:=FRect.top;
    if value.Right > FRect.right then value.right:=FRect.right;
    if value.Bottom > FRect.bottom then value.bottom:=FRect.bottom;
  end;

  Procedure TPXRRect.SetRect(aLeft,aTop,aRight,aBottom:Integer);
  Begin
    if  (aLeft<aRight)
    and (aTop<aBottom) then
    Begin
      FRect.Left:=aleft;
      FRect.top:=aTop;
      FRect.Right:=aRight;
      FRect.Bottom:=aBottom;

      if assigned(FOnAltered) then
      FOnAltered(self);
    end else
    Raise EPXRRect.Create(ERR_SLRECT_InvalidValues);
  end;

  procedure TPXRRect.setRect(aWidth,aHeight:Integer);
  Begin
    if aWidth<0 then aWidth:=PXR_positive(aWidth);
    if aHeight<0 then aHeight:=PXR_Positive(aHeight);
    if (aWidth>0) and (aHeight>0) then
    Begin
      FRect.Left:=0;
      FRect.top:=0;
      FRect.right:=aWidth;
      FRect.Bottom:=aHeight;

      if assigned(FOnAltered) then
      FOnAltered(self);
    end else
    Raise EPXRRect.Create(ERR_SLRECT_InvalidValues);
  end;

  Procedure TPXRRect.SetRect(Domain:TRect);
  Begin
    if TPXRRect.IsValid(Domain) then
    Begin
      FRect:=Domain;
      if assigned(FOnAltered) then
      FOnAltered(self);
    end else
    Raise EPXRRect.Create(ERR_SLRECT_InvalidRect);
  end;

  Procedure TPXRRect.Clear;
  Begin
    FRect:=PXR_NULLRECT;
  end;

  Function TPXRRect.Empty:Boolean;
  Begin
    result:=TPXRRect.Compare(FRect,PXR_NULLRECT)=True;
  end;

  Class Function TPXRRect.Compare(Const aFirst,aSecond:TRect):Boolean;
  Begin
    result:=(aFirst.Left=aSecond.left) and (aFirst.top=aSecond.Top)
    and (aFirst.right=aSecond.right) and (aFirst.bottom=aSecond.Bottom);
  end;

  Function TPXRRect.GetLeft:Integer;
  Begin
    result:=FRect.left;
  end;

  Function TPXRRect.GetRight:Integer;
  Begin
    result:=FRect.Right;
  end;

  Function TPXRRect.GetTop:Integer;
  Begin
    result:=FRect.top;
  end;

  Function TPXRRect.GetBottom:Integer;
  Begin
    result:=FRect.bottom;
  end;

  Function TPXRRect.GetWidth:Integer;
  Begin
    result:=(FRect.right-FRect.left) + 1;
  end;

  Function TPXRRect.getHeight:Integer;
  Begin
    result:=(FRect.bottom-FRect.top) + 1;
  end;

  Function TPXRRect.ContainsRow(Const Row:Integer):Boolean;
  Begin
    result:=(Row>=FRect.top) and (Row<=FRect.bottom);
  end;

  Function TPXRRect.ContainsColumn(Const Col:Integer):Boolean;
  Begin
    result:=(Col>=FRect.left) and (Col<=Frect.right);
  end;

  function TPXRRect.Contains(Const Child:TRect):Boolean;
  Begin
    result:=TPXRRect.IsWithin(child,FRect);
  end;

  Function TPXRRect.Contains(Const Left,Top:Integer):Boolean;
  Begin
    result:=(Left>=FRect.left) and (Left<=FRect.right)
    and (Top>=FRect.top) and (Top<=FRect.bottom);
  end;

  Function TPXRRect.Contains(Const Child:TPoint):Boolean;
  Begin
    result:=(Child.x>=FRect.left) and (Child.x<=FRect.right)
    and (Child.y>=FRect.top) and (Child.y<=FRect.bottom);
  end;

  class function TPXRRect.NullRect:TRect;
  Begin
    result:=PXR_NULLRECT;
  end;

  class function TPXRRect.MakeAbs(Const aLeft,aTop,aRight,aBottom:Integer):TRect;
  Begin
    if  (aLeft<aRight)
    and (aTop<aBottom) then
    Begin
      result.Left:=aLeft;
      result.top:=atop;
      result.Right:=aright;
      result.Bottom:=abottom;
    end else
    Raise EPXRRect.Create(ERR_SLRECT_InvalidValues);
  end;

  class function TPXRRect.Make(const aLeft,aTop,aWidth,aHeight:Integer):TRect;
  Begin
    if (aWidth>0) and (aHeight>0) then
    Begin
      result.left:=aleft;
      result.Top:=atop;
      result.right:=aleft + (awidth -1);
      result.bottom:=atop + (aheight -1);
    end else
    Raise EPXRRect.Create(ERR_SLRECT_InvalidValues);
  end;

  class function TPXRRect.IsWithin(Const Left,Top:Integer;
                 Const Domain:TRect):Boolean;
  Begin
    result:=(left>=domain.left)
    and (left<=domain.right)
    and(top>=domain.top)
    and (top<=domain.Bottom);
  end;

  class function TPXRRect.IsWithin(Const Child:TPoint;
                 Const Domain:TRect):Boolean;
  Begin
    result:=(child.X>=domain.left)
    and (child.X<=domain.right)
    and(child.Y>=domain.top)
    and (child.Y<=domain.Bottom);
  end;

  class function TPXRRect.IsWithin(Const Child:TRect;
                 Const Domain:TRect):Boolean;
  Begin
    {$B+}
    If (Child.Left>=Domain.Right)
    or (Child.Top>=Domain.Bottom)
    or (Child.Right<=Domain.Left)
    or (Child.Bottom<=Domain.Top) then
    result:=false else (* Outside *)
    if (Child.Left<Domain.Left)
    or (Child.Top<Domain.Top)
    or (Child.Right>Domain.Right-1)
    or (Child.Bottom>Domain.Bottom-1) then
    result:=false else (* Partly visible *)
    result:=True; (* Completely *)
    {$B-}
  end;

  class function TPXRRect.HeightOf(const Domain:TRect):Integer;
  Begin
    result:=Domain.bottom-Domain.top;
    if result<0 then
    result:=abs(result);
    if (Domain.top<domain.bottom)
    and (domain.top=0) then
    inc(result);
  end;

  class function TPXRRect.WidthOf(Const Domain:TRect):Integer;
  Begin
    result:=Domain.Right-Domain.left;
    if result<0 then
    result:=abs(result);
    if (Domain.left<domain.right)
    and (domain.left=0) then
    inc(result);
  end;

  class function TPXRRect.IsValid(Const Domain:TRect):Boolean;
  Begin
    result:= (Domain.Left<Domain.Right)
    and (Domain.top<Domain.bottom);
  end;

  class procedure TPXRRect.Realize(var Domain:TRect);
  Begin
    If Domain.left>Domain.right then
    PXR_SwapInt(Domain.left,Domain.right);

    If Domain.Top>Domain.Bottom then
    PXR_SwapInt(Domain.Top,Domain.Bottom);
  end;

  class function TPXRRect.Intersect(const Primary,Secondary:TRect;
                 var Intersection:TRect):Boolean;
  Begin
    Intersection:=Primary;

    if Secondary.Left>Primary.Left then
    Intersection.Left:=Secondary.Left;

    if Secondary.Top>Primary.Top then
    Intersection.Top:=Secondary.Top;

    if Secondary.Right<Primary.Right then
    Intersection.Right:=Secondary.Right;

    if Secondary.Bottom<Primary.Bottom then
    Intersection.Bottom:=Secondary.Bottom;

    Result:=(Intersection.right>Intersection.left)
    and (Intersection.bottom>Intersection.top);

    if not Result then
    Intersection:=PXR_NULLRECT;
  end;

  class procedure TPXRRect.ClipTo(var Child:TRect;Const Domain:TRect);
  Begin
    Realize(child);
    If Child.left<Domain.Left then
    Child.Left:=Domain.Left else

    if Child.left>Domain.Right then
    Child.left:=Domain.Right;

    If Child.right<Domain.Left then
    Child.right:=Domain.Left else

    if Child.right>Domain.Right
    then Child.right:=Domain.Right;

    if Child.Top<Domain.Top then
    Child.top:=Domain.Top else

    if Child.top>Domain.bottom then
    Child.top:=Domain.bottom;

    if Child.bottom<Domain.Top then
    Child.bottom:=Domain.Top else

    if Child.bottom>Domain.bottom then
    Child.bottom:=Domain.Bottom;
  end;

  class function TPXRRect.isVisible(Const Child,Domain:TRect):TPXRRectExposure;
  Begin
    {$B+}
    If (Child.Left>=Domain.Right)
    or (Child.Top>=Domain.Bottom)
    or (Child.Right<=Domain.Left)
    or (Child.Bottom<=Domain.Top) then
    result:=esNone else
    if (Child.Left<Domain.Left)
    or (Child.Top<Domain.Top)
    or (Child.Right>Domain.Right-1)
    or (Child.Bottom>Domain.Bottom-1) then
    result:=esPartly else
    result:=esCompletely;
    {$B-}
  end;

  class function TPXRRect.toString(const Domain:TRect;
        Const Full:Boolean=True):String;
  Begin
    if Full then
    result:=Format('{%d,%d - %d,%d} Width:%d Height:%d',
    [domain.left,domain.top,domain.right,domain.Bottom,
    (TPXRRect.WidthOf(domain)),(TPXRRect.HeightOf(domain))]) else
    result:=Format('{%d,%d - %d,%d}',
    [domain.left,domain.top,domain.right,domain.Bottom]);
  end;

  Class function TPXRRect.toPoints(const Domain:TRect):TPXRPointArray;
  Begin
    setlength(result,4);
    result[0]:=Point(domain.Left,domain.top);
    result[1]:=Point(domain.Right,domain.top);
    result[2]:=point(domain.right,domain.bottom);
    result[3]:=point(domain.left,domain.bottom);
  end;

  //###########################################################################
  //  TPXRColorPresets
  //###########################################################################

  Constructor TPXRColorPresets.Create(AOwner:TPXRColorCustom);
  Begin
    inherited Create;
    FParent:=AOwner;
  end;

  Procedure TPXRColorPresets.White;
  Begin
    FParent.ColorRef:=$00FFFFFF;
  end;

  procedure TPXRColorPresets.Black;
  Begin
    FParent.ColorRef:=$00000000;
  end;

  Procedure TPXRColorPresets.Red;
  Begin
    FParent.ColorRef:=$00FF0000;
  end;

  Procedure TPXRColorPresets.Green;
  Begin
    FParent.ColorRef:=$0000FF00;
  end;

  Procedure TPXRColorPresets.Blue;
  Begin
    FParent.ColorRef:=$000000FF;
  end;

  Procedure TPXRColorPresets.Cyan;
  Begin
    FParent.ColorRef:=$0000FFFF;
  end;

  Procedure TPXRColorPresets.Magenta;
  Begin
    FParent.ColorRef:=$00FF00FF;
  end;

  Procedure TPXRColorPresets.Indigo;
  Begin
    FParent.ColorRef:=$004B0082;
  end;

  Procedure TPXRColorPresets.Violet;
  Begin
    FParent.ColorRef:=$00EE82EE;
  end;

  Procedure TPXRColorPresets.Gold;
  Begin
    FParent.ColorRef:=$00FFD700;
  end;

  Procedure TPXRColorPresets.Khaki;
  Begin
    FParent.ColorRef:=$00F0E68C;
  end;

  Procedure TPXRColorPresets.Orange;
  Begin
    FParent.ColorRef:=$00FFA500;
  end;
  Procedure TPXRColorPresets.Tomato;
  Begin
    FParent.ColorRef:=$00FF6347;
  end;

  Procedure TPXRColorPresets.Pink;
  Begin
    FParent.ColorRef:=$00FFC0CB;
  end;

  Procedure TPXRColorPresets.LimeGreen;
  Begin
    FParent.ColorRef:=$0032CD32;
  end;


  //###########################################################################
  // TPXRColorCustom
  //###########################################################################

  Constructor TPXRColorCustom.Create;
  Begin
    inherited;
    FPresets:=TPXRColorPresets.Create(self);
  end;

  Destructor TPXRColorCustom.Destroy;
  Begin
    FPresets.free;
    inherited;
  end;

  Procedure TPXRColorCustom.AfterConstruction;
  Begin
    Inherited;
    FBusy:=True;
    try
      SetColorRef(clWhite);
    finally
      FBusy:=False;
    end;
  end;

  class function TPXRColorCustom.Ramp(Const Value:TColor;
        aCount:Byte;Style:TPXRRampType):TPXRColorArray;
  var
    x:        Integer;
    mFactor:  Integer;
    r,g,b:    Byte;
  Begin
    setlength(result,aCount);
    if aCount>0 then
    Begin
      result[Low(result)]:=Value;
      if aCount>1 then
      Begin
        decode(value,r,g,b);
        mFactor := 255 div aCount;
        for x:=low(result)+1 to high(result) do
        Begin
          case style of
          rtRampUp:
            Begin
              r:=math.EnsureRange(r + mFactor,0,255);
              g:=math.EnsureRange(g + mFactor,0,255);
              b:=math.EnsureRange(b + mFactor,0,255);
            End;
          rtRampDown:
            Begin
              r:=math.EnsureRange(r - mFactor,0,255);
              g:=math.EnsureRange(g - mFactor,0,255);
              b:=math.EnsureRange(b - mFactor,0,255);
            End;
          end;
          result[x]:=encode(r,g,b);
        end;
      end;
    end;
  end;

  {$IFDEF MSWINDOWS}
  Class function TPXRColorCustom.CheckSysColor(Const Value:TColor):Boolean;
  Begin
    result:=( (Value shr 24)=$FF );
  end;
  {$ENDIF}

  procedure TPXRColorCustom.AssignTo(Dest:TPersistent);
  Begin
    if Dest<>NIL then
    Begin
      if (Dest is TPXRColorCustom) then
      TPXRColorCustom(dest).ColorRef:=FColorRef else

      if (Dest is TCanvas) then
      TCanvas(dest).Pen.Color:=FColorRef else

      if (Dest is TPen) then
      TPen(Dest).Color:=FColorRef else

      if (Dest is TBrush) then
      TBrush(Dest).Color:=FColorRef else

      inherited;
    end else
    inherited;
  end;

  Function TPXRColorCustom.toHTML:String;
  Begin
    Result:='#' + IntToHex(FRed,2)
    + IntToHex(FGreen,2)
    + IntToHex(FBlue,2);
  end;

  Procedure TPXRColorCustom.TripletsChanged;
  Begin
    FColorRef:=Encode(FRed,FGreen,FBlue);
    if not FBusy then
    Begin
      if assigned(FOnChange) then
      FOnChange(self);
    end;
  end;

  Procedure TPXRColorCustom.SetRed(Const Value:Byte);
  Begin
    If Value<>FRed then
    Begin
      FRed:=Value;
      TripletsChanged;
    end;
  end;

  Procedure TPXRColorCustom.SetGreen(Const Value:Byte);
  Begin
    If Value<>FGreen then
    Begin
      FGreen:=Value;
      TripletsChanged;
    end;
  end;

  procedure TPXRColorCustom.SetBlue(Const Value:Byte);
  Begin
    If Value<>FBlue then
    Begin
      FBlue:=Value;
      TripletsChanged;
    end;
  end;

  Procedure TPXRColorCustom.SetColorRef(Const Value:TColor);
  Begin
    Decode(Value,FRed,FGreen,FBlue);
    TripletsChanged;
  end;

  Procedure TPXRColorCustom.SetRGB(aRed,aGreen,aBlue:Byte);
  Begin
    If (aRed<>FRed)
    or (aGreen<>FGreen)
    or (aBlue<>FBlue) then
    Begin
      FRed:=aRed;
      FGreen:=aGreen;
      FBlue:=aBlue;
      TripletsChanged;
    end;
  end;

  Function TPXRColorCustom.BlendTo(Const Value:TColor;Const Factor:Byte):TColor;
  var
    rd,gd,bd,
    rx,gx,bx: Byte;
  Begin
    Decode(Value,Rd,Gd,Bd);
    rx:=Byte(((FRed-rd) * Factor) shr 8 + rd);
    gx:=Byte(((FGreen-gd) * Factor) shr 8 + gd);
    bx:=Byte(((FBlue-bd) * Factor) shr 8 + bd);
    result:=Encode(rx,gx,bx);
  end;

  Procedure TPXRColorCustom.BlendFrom(Const Value:TColor;Const Factor:Byte);
  var
    rd,gd,bd,
    rx,gx,bx: Byte;
  Begin
    Decode(Value,Rd,Gd,Bd);
    rx:=Byte(((FRed-rd) * Factor) shr 8 + rd);
    gx:=Byte(((FGreen-gd) * Factor) shr 8 + gd);
    bx:=Byte(((FBlue-bd) * Factor) shr 8 + bd);
    SetRGB(rx,gx,bx);
  end;

  procedure TPXRColorCustom.GetHSV(var H,S,V:Integer);
  var
    Delta:  Integer;
    Min:    Integer;
  begin
    (* Find largest *)
    V:=FRed;
    If FGreen>V then
    V:=FGreen else
    If FBlue>V then
    V:=FBlue;

    (* Find smallest *)
    Min:=FRed;
    If FGreen<Min then
    min:=FGreen else
    if FBlue<Min then
    min:=FBlue;

    Delta:=V-Min;

    if V = 0 then
    S := 0 else
    S := MulDiv(Delta, 255, V);

    if S = 0 then
    H := 0 else
    begin
      If FRed=V then
      H:=MulDiv(FGreen - FBlue, 60, Delta) else
      If FGreen=V then
      H:=120 + MulDiv(FBlue - FRed, 60, Delta) else
      if FBlue=V then
      H := 240 + MulDiv(FRed - FGreen, 60, Delta);
      if H < 0 then H := H + 360;
    end
  end;

  Procedure TPXRColorCustom.SetHSV(const H,S,V:Integer);
  const
    divisor: Integer = 255 * 60;
  var
    FTemp:    Integer;
    f,p,q,t:  Integer;
    Vs:       Integer;
  begin
    if S = 0 then
    SetRGB(V,V,V) else
    begin
      if H = 360 then
      FTemp := 0 else
      FTemp := H;

      f := FTemp mod 60;
      FTemp := FTemp div 60;

      VS := V * S;
      p := V - VS div 255;
      q := V - (VS * f) div divisor;
      t := V - (VS * (60 - f)) div divisor;

      case FTemp of
        0:  SetRGB(V,T,P);
        1:  SetRGB(Q,V,P);
        2:  SetRGB(P,V,T);
        3:  SetRGB(P,Q,V);
        4:  SetRGB(T,P,V);
        5:  SetRGB(V,P,Q);
      else  SetRGB(0,0,0);
      end
    end
  end;

  Procedure TPXRColorCustom.Invert;
  Begin
    FRed:=(255 - FRed);
    FGreen:=(255 - FGreen);
    FBlue:=(255 - FBlue);
    Tripletschanged;
  end;

  Function TPXRColorCustom.Luminance:Integer;
  Begin
    Result:=trunc( (0.3 * FRed) + (0.59 * FGreen) + (0.11 * FBlue) );
  end;

  Procedure TPXRColorCustom.Balance;
  Begin
    FRed:=((FRed shr 2) shl 2);
    FGreen:=((FGreen shr 2) shl 2);
    FBlue:=((FBlue shr 2) shl 2);
    Tripletschanged;
  end;

  Procedure TPXRColorCustom.Darker(Const Percent:TPXRColorPercent);
  Begin
    If Percent>0 then
    Begin
      FRed := math.EnsureRange(FRed - Round(FRed*Percent/100),0,255);
      FGreen := math.EnsureRange(FGreen - Round(FGreen*Percent/100),0,255);
      FBlue := math.EnsureRange(FBlue - Round(FBlue*Percent/100),0,255);
      Tripletschanged;
    end;
  end;

  Procedure TPXRColorCustom.Brighter(Const Percent:TPXRColorPercent);
  Begin
    If Percent>0 then
    Begin
      FRed := Round(FRed*Percent/100) + Round(255 - Percent/100*255);
      FGreen := Round(FGreen*Percent/100) + Round(255 - Percent/100*255);
      FBlue := Round(FBlue*Percent/100) + Round(255 - Percent/100*255);
      Tripletschanged;
    end;
  end;

  Procedure TPXRColorCustom.toRGB15(var buffer);
  Begin
    ColorTo15(FColorRef,Buffer);
  end;

  Procedure TPXRColorCustom.toRGB16(var buffer);
  Begin
    ColorTo16(FColorRef,Buffer);
  end;

  Procedure TPXRColorCustom.toRGB24(var buffer);
  Begin
    ColorTo24(FColorRef,Buffer);
  end;

  Procedure TPXRColorCustom.toRGB32(var buffer);
  Begin
    ColorTo32(FColorRef,Buffer);
  end;

  Procedure TPXRColorCustom.fromRGB15(Const buffer);
  Begin
    SetColorRef(ColorFrom15(buffer));
  end;

  Procedure TPXRColorCustom.fromRGB16(Const buffer);
  Begin
    SetColorRef(ColorFrom16(buffer));
  end;

  Procedure TPXRColorCustom.fromRGB24(Const buffer);
  Begin
    SetColorRef(ColorFrom24(buffer));
  end;

  Procedure TPXRColorCustom.fromRGB32(Const buffer);
  Begin
    SetColorRef(ColorFrom32(buffer));
  end;

  Class procedure TPXRColorCustom.Decode(Value:TColor;
        Var Red,Green,Blue:Byte);
  Begin
    {$IFDEF MSWINDOWS}
    If CheckSysColor(value) then
    Value:=graphics.ColorToRGB(Value);
    {$ENDIF}
    red:=Byte(Value);
    green:=Byte(Value shr 8);
    blue:=Byte(Value shr 16);
  end;

  Class Function TPXRColorCustom.Invert(Const Value:TColor):TColor;
  var
    R,G,B:Byte;
  Begin
    Decode(Value,R,G,B);
    Result:=Encode((255 - R),(255 - G),(255 - B));
  end;

  Class Function TPXRColorCustom.Encode(Const R,G,B:Byte):TColor;
  Begin
    result:=(r or (g shl 8) or (b shl 16));
  end;

  Class Function TPXRColorCustom.Blend(Const First,Second:TColor;
        Const Factor:TPXRColorPercent):TColor;
  var
    rd,gd,bd,
    rx,gx,bx,
    rc,gc,bc: Byte;
  Begin
    Decode(First,Rd,Gd,Bd);
    Decode(Second,Rx,Gx,Bx);
    rc:=Byte(((Rx-rd) * Factor) shr 8 + rd);
    gc:=Byte(((Gx-gd) * Factor) shr 8 + gd);
    bc:=Byte(((Bx-bd) * Factor) shr 8 + bd);
    result:=(rc or (gc shl 8) or (bc shl 16));
  end;

  Class Function TPXRColorCustom.Luminance(Const Value:TColor):Integer;
  var
    R,G,B:Byte;
  Begin
    Decode(Value,R,G,B);
    Result:=trunc( (0.3 * R) + (0.59 * G) + (0.11 * B) );
  end;

  Class Function TPXRColorCustom.Balance(Const Value:TColor):TColor;
  var
    R,G,B:Byte;
  Begin
    Decode(Value,R,G,B);
    Result:=Encode(((R shr 2) shl 2),
    ((G shr 2) shl 2),((B shr 2) shl 2));
  end;

  Class Procedure TPXRColorCustom.RGBTo15(var buffer;Const R,G,B:Byte);
  Begin
    word(buffer):=(R shr 3) shl 10 or (G shr 3) shl 5 or (B shr 3);
  end;

  Class procedure TPXRColorCustom.RGBTo16(var buffer;Const R,G,B:Byte);
  Begin
    word(buffer):=(R shr 3) shl 11 or (G shr 2) shl 5 or (B shr 3);
  end;

  Class Procedure TPXRColorCustom.RGBTo24(var buffer;Const R,G,B:Byte);
  Begin
    TRGBTriple(buffer).rgbtRed:= R;
    TRGBTriple(buffer).rgbtGreen:= G;
    TRGBTriple(buffer).rgbtBlue:= B;
  end;

  Class procedure TPXRColorCustom.RGBTo32(var buffer;Const R,G,B:Byte);
  Begin
    TRGBQuad(buffer).rgbRed:= R;
    TRGBQuad(buffer).rgbGreen:= G;
    TRGBQuad(buffer).rgbBlue:= B;
  end;

  Class Procedure TPXRColorCustom.RGBFrom15(Const buffer;var R,G,B:Byte);
  Begin
    r:=Byte(((word(buffer) and $7C00) shr 10) shl 3);
    g:=Byte(((word(buffer) and $03E0) shr 5) shl 3);
    b:=Byte((word(buffer) and $001F) shl 3);
  end;

  Class procedure TPXRColorCustom.RGBFrom16(Const buffer;var R,G,B:Byte);
  Begin
    r:=Byte(((word(buffer) and $F800) shr 11) shl 3);
    g:=Byte(((word(buffer) and $07E0) shr 5) shl 2);
    b:=Byte((word(buffer) and $001F) shl 3);
  end;

  Class Procedure TPXRColorCustom.RGBFrom24(Const buffer;var R,G,B:Byte);
  Begin
    R:=TRGBTriple(buffer).rgbtRed;
    G:=TRGBTriple(buffer).rgbtGreen;
    B:=TRGBTriple(buffer).rgbtBlue;
  end;

  Class procedure TPXRColorCustom.RGBFrom32(Const buffer;var R,G,B:Byte);
  Begin
    R:=TRGBQuad(buffer).rgbRed;
    G:=TRGBQuad(buffer).rgbGreen;
    B:=TRGBQuad(buffer).rgbBlue;
  end;

  Class Function TPXRColorCustom.ColorFrom15(Const Buffer):TColor;
  var
    r,g,b:  Byte;
  Begin
    r:=((word(Buffer) and $7C00) shr 10) shl 3;
    g:=((word(Buffer) and $03E0) shr 5) shl 3;
    b:= (word(Buffer) and $001F) shl 3;
    result:=Encode(r,g,b);
  end;

  Class Function TPXRColorCustom.ColorFrom16(Const Buffer):TColor;
  var
    r,g,b:  Byte;
  Begin
    r:=((word(Buffer) and $F800) shr 11) shl 3;
    g:=((word(Buffer) and $07E0) shr 5) shl 2;
    b:=(word(Buffer) and $001F) shl 3;
    result:=Encode(r,g,b);
  end;

  Class Function TPXRColorCustom.ColorFrom24(Const Buffer):TColor;
  Begin
    result:=Encode(TRGBTriple(buffer).rgbtRed,TRGBTriple(buffer).rgbtGreen,
    TRGBTriple(buffer).rgbtBlue);
  end;

  Class Function TPXRColorCustom.ColorFrom32(Const Buffer):TColor;
  Begin
    result:=Encode(TRGBQuad(buffer).rgbRed,TRGBQuad(buffer).rgbGreen,
    TRGBQuad(buffer).rgbBlue);
  end;

  Class Procedure TPXRColorCustom.ColorTo15(Const Color:TColor;var Buffer);
  var
    r,g,b:  Byte;
  Begin
    Decode(Color,R,G,B);
    word(buffer):= ((r shr 3) shl 10) + ((g shr 3) shl 5) + (b shr 3);
  end;

  Class Procedure TPXRColorCustom.ColorTo16(Const Color:TColor;var Buffer);
  var
    r,g,b:  Byte;
  Begin
    Decode(Color,R,G,B);
    Word(Buffer):= ((r shr 3) shl 11) + ((g shr 2) shl 5) + (b shr 3);
  end;

  Class Procedure TPXRColorCustom.ColorTo24(Const Color:TColor;var Buffer);
  Begin
    Decode(Color,TRGBTriple(buffer).rgbtRed,TRGBTriple(buffer).rgbtGreen,
    TRGBTriple(buffer).rgbtBlue);
  end;

  Class Procedure TPXRColorCustom.ColorTo32(Const Color:TColor;var Buffer);
  Begin
    Decode(Color,TRGBQuad(buffer).rgbRed,TRGBQuad(buffer).rgbGreen,
    TRGBQuad(buffer).rgbBlue);
  end;

  class procedure TPXRColorCustom.Blend15(const first;
        const second;Const Alpha:Byte;var target);
  var
    rs,gs,bs,
    rd,gd,bd: Byte;
    rx,gx,bx: Byte;
  Begin
    rs:=((Word(first) and $7C00) shr 10) shl 3;
    gs:=((Word(first) and $03E0) shr 5) shl 3;
    bs:= (Word(first) and $001F) shl 3;

    rd:=((Word(second) and $7C00) shr 10) shl 3;
    gd:=((Word(second) and $03E0) shr 5) shl 3;
    bd:= (Word(second) and $001F) shl 3;

    rx:=Byte(((rs-rd) * Alpha) shr 8 + rd);
    gx:=Byte(((gs-gd) * Alpha) shr 8 + gd);
    bx:=Byte(((bs-bd) * Alpha) shr 8 + bd);

    Word(target):=(Rx shr 3) shl 10 + (Gx shr 3) shl 5 + (Bx shr 3);
  end;

  class procedure TPXRColorCustom.Blend16(const first;
        const second;Const Alpha:Byte;var target);
  var
    rs,gs,bs,
    rd,gd,bd: Byte;
    rx,gx,bx: Byte;
  Begin
    rs:=((Word(first) and $F800) shr 11) shl 3;
    gs:=((Word(first) and $07E0) shr 5) shl 2;
    bs:=(Word(first) and $001F) shl 3;

    rd:=((Word(second) and $F800) shr 11) shl 3;
    gd:=((Word(second) and $07E0) shr 5) shl 2;
    bd:=(Word(second) and $001F) shl 3;

    rx:=byte(((rs-rd) * Alpha) shr 8 + rd);
    gx:=byte(((gs-gd) * Alpha) shr 8 + gd);
    bx:=byte(((bs-bd) * Alpha) shr 8 + bd);

    Word(target):=(Rx shr 3) shl 11 or (Gx shr 2) shl 5 or (Bx shr 3);
  end;

  class procedure TPXRColorCustom.Blend24(const first;
        const second;Const Alpha:Byte;var target);
  var
    rs,gs,bs,
    rd,gd,bd: Byte;
  Begin
    With TRGBTriple(first) do
    Begin
      rs:=rgbtRed;
      gs:=rgbtGreen;
      bs:=rgbtBlue;
    end;

    With TRGBTriple(second) do
    Begin
      rd:=rgbtRed;
      gd:=rgbtGreen;
      bd:=rgbtBlue;
    end;

    with TRGBTriple(target) do
    Begin
      rgbtRed:=byte(((rs-rd) * Alpha) shr 8 + rd);
      rgbtGreen:=byte(((gs-gd) * Alpha) shr 8 + gd);
      rgbtBlue:=byte(((bs-bd) * Alpha) shr 8 + bd);
    end;
  end;

  class procedure TPXRColorCustom.Blend32(const first;
        const second;Const Alpha:Byte;var target);
  var
    rs,gs,bs,
    rd,gd,bd: Byte;
  Begin
    with TRGBQuad(first) do
    Begin
      rs:=rgbRed;
      gs:=rgbGreen;
      bs:=rgbBlue;
    end;

    With TRGBQuad(second) do
    Begin
      rd:=rgbRed;
      gd:=rgbGreen;
      bd:=rgbBlue;
    end;

    With TRGBQuad(target) do
    Begin
      rgbRed:=byte(((rs-rd) * Alpha) shr 8 + rd);
      rgbGreen:=byte(((gs-gd) * Alpha) shr 8 + gd);
      rgbBlue:=byte(((bs-bd) * Alpha) shr 8 + bd);
    end;
  end;


  //###########################################################################
  //  TPXRPaletteColor
  //###########################################################################

  class procedure TPXRPaletteColor.Blend08(Const Palette:TPXRPaletteCustom;
        const first;const second;
        Const Alpha:Byte;var target);
  var
    rs,gs,bs,
    rd,gd,bd: Byte;
    rx,gx,bx: Byte;
  Begin
    if Palette<>NIl then
    Begin
      Palette.ExportRGB(Byte(first),rs,gs,bs);
      Palette.ExportRGB(Byte(second),rd,gd,bd);
      rx:=Byte(((rs-rd) * Alpha) shr 8 + rd);
      gx:=Byte(((gs-gd) * Alpha) shr 8 + gd);
      bx:=Byte(((bs-bd) * Alpha) shr 8 + bd);
      Byte(target):=Palette.Match(rx,gx,bx);
    end;
  end;

  class Function TPXRPaletteColor.ColorFrom08
        (Const Palette:TPXRPaletteCustom;Const Buffer):TColor;
  Begin
    if Palette<>NIl then
    result:=Palette.Items[Byte(Buffer)] else
    result:=graphics.clNone;
  end;

  Class Procedure TPXRPaletteColor.ColorTo08
        (Const Color:TColor;Const Palette:TPXRPaletteCustom;var Buffer);
  Begin
    if Palette<>NIl then
    Byte(buffer):=Palette.Match(Color);
  end;

  Procedure TPXRPaletteColor.toRGB08
        (Const Palette:TPXRPaletteCustom;var buffer);
  Begin
    if palette<>NIL then
    Byte(buffer):=palette.Match(Red,Green,Blue);
  end;

  Class Procedure TPXRPaletteColor.RGBFrom08
        (Const Palette:TPXRPaletteCustom;const buffer;var R,G,B:Byte);
  Begin
    If Palette<>NIL then
    Palette.ExportRGB(Byte(buffer),R,G,B);
  end;
  
  //###########################################################################
  //  TPXRPaletteNetScape
  //###########################################################################

  Constructor TPXRPaletteNetscape.Create;
  var
    FIndex: Integer;
    r,g,b:  Byte;
  begin
    inherited;
    for r:=0 to 5 do
    for g:=0 to 5 do
    for b:=0 to 5 do
    Begin
      FIndex:=b + g*6 + r*36;
      FQuads[FIndex].rgbRed:=r * 51;
      FQuads[FIndex].rgbGreen:=g * 51;
      FQuads[FIndex].rgbBlue:=b * 51;
    end;
  end;

  Procedure TPXRPaletteNetScape.ExportRGB(Const index:Integer;var R,G,B:Byte);
  Begin
    if (index>=0) and (index<CNT_SLPALETTE_NETSCAPE_COUNT) then
    Begin
      r:=FQuads[index].rgbRed;
      g:=FQuads[index].rgbGreen;
      b:=FQuads[index].rgbBlue;
    end else
    Raise EPXRPalette.CreateFmt
    (ERR_SLPALETTE_INVALIDCOLORINDEX,[0,GetCount-1,index]);
  end;
  
  Function TPXRPaletteNetScape.Match(r,g,b:Byte):Integer;
  Begin
    R := (R+25) div 51;
    G := (G+25) div 51;
    B := (B+25) div 51;
    result:=(B + 6 * G + 36 * R);
  end;
  
  Function TPXRPaletteNetScape.GetReadOnly:Boolean;
  Begin
    result:=True;
  end;
  
  Procedure TPXRPaletteNetScape.GetItemQuad(Index:Integer;Var Data);
  Begin
    If (Index>=0) and (index<CNT_SLPALETTE_NETSCAPE_COUNT) then
    TRGBQuad(Data):=FQuads[index] else
    Raise EPXRPalette.CreateFmt
    (ERR_SLPALETTE_INVALIDCOLORINDEX,[0,215,index]);
  end;

  Function TPXRPaletteNetScape.GetCount:Integer;
  Begin
    result:=CNT_SLPALETTE_NETSCAPE_COUNT;
  end;

  Function TPXRPaletteNetScape.GetItem(index:Integer):TColor;
  var
    FTemp:  PRGBQuad;
  Begin
    If (Index>=0) and (index<CNT_SLPALETTE_NETSCAPE_COUNT) then
    Begin
      FTemp:=@FQuads[index];
      Result := (FTemp^.rgbRed
      or (FTemp^.rgbGreen shl 8)
      or (FTemp^.rgbBlue shl 16));
    end else
    Raise EPXRPalette.CreateFmt
    (ERR_SLPALETTE_INVALIDCOLORINDEX,[0,CNT_SLPALETTE_NETSCAPE_COUNT-1,index]);  
  end;

  Procedure TPXRPaletteNetScape.SetItem(Index:Integer;Value:TColor);
  Begin
    Raise EPXRPalette.Create(ERR_SLPALETTE_PALETTEREADONLY);
  end;

  //###########################################################################
  //  TPXRPaletteCustom
  //###########################################################################

  procedure TPXRPaletteCustom.AssignTo(Dest: TPersistent);
  var
    x:  Integer;
  Begin
    If Dest<>NIL then
    Begin
      if (dest is TPXRPaletteCustom) then
      Begin
        if not TPXRPaletteCustom(dest).ReadOnly then
        Begin
          for x:=1 to GetCount do
          TPXRPaletteCustom(dest).Items[x-1]:=Items[x-1];
        end else
        Raise EPXRPalette.Create(ERR_SLPALETTE_ASSIGNToREADONLY);
      end else
      Inherited;
    end else
    Inherited;
  end;
  
  Function TPXRPaletteCustom.GetByteSize:Integer;
  Begin
    result:=SizeOf(TRGBQuad) * GetCount;
  end;

  Procedure TPXRPaletteCustom.ExportRGB(Const index:Integer;var R,G,B:Byte);
  var
    FTemp:  TColor;
  Begin
    if (index>=0) and (index<GetCount) then
    Begin
      FTemp:=GetItem(index);
      R:=Byte(FTemp);
      G:=Byte(FTemp shr 8);
      B:=Byte(FTemp shr 16);
    end else
    Raise EPXRPalette.CreateFmt
    (ERR_SLPALETTE_INVALIDCOLORINDEX,[0,GetCount-1,index]);
  end;

  function TPXRPaletteCustom.ExportColorObj(const index:Byte):TPXRPaletteColor;
  Begin
    result:=TPXRPaletteColor.Create;
    result.ColorRef:=Items[index];
  end;

  Procedure TPXRPaletteCustom.ExportQuadArray(Const Target);
  var
    x:      Integer;
    FCount: Integer;
    FData:  PRGBQuadArray;
  Begin
    FData:=@Target;
    If FData<>NIl then
    Begin
      FCount:=GetCount;
      for x:=1 to FCount do
      GetItemQuad(x-1,FData^[x-1]);
    end;
  end;

  Function TPXRPaletteCustom.Match(Value:TColor):Integer;
  Begin
    (* If palette reference, convert to RGB color *)
    {$IFDEF PXR_USE_WINDOWS}
    If (Value shr 24)=$FF then
    Value:=GetSysColor(Value and $000000FF);
    {$ENDIF}

    (* Look it up. It's up to the implementor of the class to at least
       be able to match colors by RGB *)
    result:=Match(Byte(value),Byte(value shr 8),Byte(value shr 16));
  end;


  //###########################################################################
  //  TPXRSurfaceUNI
  //###########################################################################

  Procedure TPXRSurfaceUNI.PaletteChange(NewPalette:TPXRPaletteCustom);
  Begin
    //
  end;

  Function TPXRSurfaceUNI.GetScanLine(Const Row:Integer):PByte;
  Begin
    if FBuffer<>NIL then
    Begin
      if  (Row>=0)
      and (Row<Height) then
      Begin
        Result:=FBuffer;
        inc(result,Pitch * Row);
      end else
      Raise EPXRSurfaceCustom.CreateFmt
      (ERR_SLSURFACE_INVALIDCORDINATE,[0,Row]);
    end else
    Raise EPXRSurfaceCustom.Create
    (ERR_SLSURFACE_NotAllocated);
  end;

  Function TPXRSurfaceUNI.GetEmpty:Boolean;
  Begin
    result:=FBuffer=NIL;
  end;

  Procedure TPXRSurfaceUNI.ReleaseSurface;
  Begin
    try
      FreeMem(FBuffer);
    finally
      FBuffer:=NIL;
      FBufSize:=0;
    end;
  end;

  Procedure TPXRSurfaceUNI.AllocSurface(var aWidth,aHeight:Integer;
            var aFormat:TPixelFormat;
            out aPitch:Integer;
            out aBufferSize:Integer);
  Begin
    if (aFormat in [pf8bit..pf32bit]) then
    Begin
      (* Calculate pitch *)
      aPitch:=GetStrideAlign(aWidth,GetPerPixelBytes(aFormat));

      (* Calculate BufferSize *)
      aBufferSize:=aPitch * aHeight;

      (* Allocate memory *)
      try
        FBuffer:=AllocMem(aBufferSize);
      except
        on e: exception do
        Begin
          aPitch:=0;
          aBufferSize:=0;
          Raise EPXRSurfaceCustom.CreateFmt
          (ERR_SLSURFACE_FAILEDALLOCATE,[e.message]);
        end;
      end;

    end else
    Raise EPXRSurfaceCustom.Create(ERR_SLSURFACE_UNSUPPORTEDFORMAT);
  end;

  //###########################################################################
  //  TPXRSurfaceDIB
  //###########################################################################

  {$IFDEF MSWINDOWS}
  Procedure TPXRSurfaceDIB.PaletteChange(NewPalette:TPXRPaletteCustom);
  var
    FTemp:  TRGBQuadArray;
  Begin
    If NewPalette<>NIL then
    Begin
      if not Empty then
      Begin
        Fillchar(FTemp,SizeOf(FTemp),#0);
        NewPalette.ExportQuadArray(FTemp);
        SetDIBColorTable(FDC,0,Palette.Count,FTemp);
      end;
    end;
  end;

  Procedure TPXRSurfaceDIB.AllocSurface(var aWidth,aHeight:Integer;
            var aFormat:TPixelFormat;
            out aPitch:Integer;
            out aBufferSize:Integer);
  Const
    BitComp: Array[pf8Bit..pf32Bit] of Integer
    = (BI_RGB,BI_BITFIELDS,BI_BITFIELDS,BI_RGB,BI_RGB);
  var
    FSize:  Integer;
    FFace:  PLongword;
  Begin
    (* Allocate Device context *)
    FDC:=CreateCompatibleDC(0);
    if FDC<>0 then
    Begin
      (* Calculate size of BitmapInfo structure *)
      If aFormat=pf8Bit then
      Begin
        FSize:=SizeOf(TBitmapInfo);
        If Palette<>NIL then
        inc(FSize,Palette.Size);
      end else
      FSize:=SizeOf(TBitmapInfo) + (002 * SizeOf(DWord));

      (* Allocate bitmapinfo *)
      try
        FDInfo:=Allocmem(FSize);
      except
        on e: exception do
        Begin
          DeleteDC(FDC);
          Raise EPXRSurfaceCustom.CreateFmt
          (ERR_SLSURFACE_FAILEDALLOCATE,[e.message]);
        end;
      end;

      (* Populate info header  *)
      Fillchar(FDInfo^,FSize,#0);
      FDInfo^.bmiHeader.biSize:=SizeOf(TBitmapInfoHeader);
      FDInfo^.bmiHeader.biBitCount:=GetPerPixelBits(aFormat);
      FDInfo^.bmiHeader.biPlanes:=1;
      FDInfo^.bmiHeader.biWidth:=aWidth;
      FDInfo^.bmiHeader.biHeight:=-abs(aHeight);
      FDInfo^.bmiHeader.biCompression:=BitComp[aFormat];

      FFace:=@FDInfo^.bmiColors[0];
      Case aFormat of
      pf8Bit:
        Begin
          If Palette<>NIL then
          Begin
            FDInfo^.bmiHeader.biClrUsed:=Palette.Count;
            Palette.ExportQuadArray(FFace^);
          end;
        end;
      pf15Bit:
        Begin
          FFace^:=$7C00; inc(FFace);
          FFace^:=$03E0; inc(FFace);
          FFace^:=$03E0;
        end;
      pf16Bit:
        Begin
          FFace^:=$F800; inc(FFace);
          FFace^:=$07E0; inc(FFace);
          FFace^:=$001F;
        end;
      end;

      (* Allocate DIB section *)
      FBitmap:=CreateDibSection(0,FDInfo^,DIB_RGB_COLORS,FBuffer,0,0);
      If FBitmap=0 then
      Begin
        (* Release device context *)
        DeleteDC(FDC);

        (* Release Bitmap Info *)
        FreeMem(FDInfo);

        (* Reset variables *)
        FBitmap:=0;
        FOldBmp:=0;
        FBuffer:=NIL;
        FDInfo:=NIL;
        FDC:=0;

        (* Raise system exception *)
        Raise EPXRSurfaceCustom.CreateFmt
        (ERR_SLSURFACE_FAILEDALLOCATE,
        [SysErrorMessage(windows.GetLastError)]);
      end;

      (* Select bitmap into device context *)
      FOldBmp:=SelectObject(FDC,FBitmap);

      (* Return pitch as well *)
      aPitch:=GetStrideAlign(aWidth,GetPerPixelBytes(aFormat));
    end;
  end;

  (* Overrides Ancestor:
     This function returns a pointer to a surface
     scanline. In a perfect world all bitmaps would be linear - but
     sadly some systems map scanlines to different regions of memory.
     So there is no guarante that Line 1 equals Line 0 + (width * pixelsize).
     Well, better reliable and slow than fast an out of control *)
  Function TPXRSurfaceDIB.GetScanLine(Const Row:Integer):PByte;
  Begin
    (* Check if buffer is there. Strictly speaking not required, if we get
       this far it's always ready - but good form non-the-less *)
    if FBuffer<>NIL then
    Begin
      (* vertically within range? *)
      if  (Row>=0)
      and (Row<Height) then
      Begin
        (* return base addr and "inc-up" the row *)
        Result:=FBuffer;
        inc(result,Pitch * Row);
      end else
      Raise EPXRSurfaceCustom.CreateFmt
      (ERR_SLSURFACE_INVALIDCORDINATE,[0,Row]);
    end else
    Raise EPXRSurfaceCustom.Create
    (ERR_SLSURFACE_NotAllocated);
  end;

  (* Overrides Ancestor: *)
  Function TPXRSurfaceDIB.GetEmpty:Boolean;
  Begin
    result:=FBuffer=NIL;
  end;

  Procedure TPXRSurfaceDIB.ReleaseSurface;
  Begin
    if not GetEmpty then
    Begin
      try
        (* re-insert original bitmap handle *)
        SelectObject(FDC,FOldBmp);

        (* Delete our bitmap. This also deletes the dibsection *)
        DeleteObject(FBitmap);

        (* Delete device context *)
        DeleteDC(FDC);
      finally
        if FDInfo<>NIl then
        FreeMem(FDInfo);

        FBitmap:=0;
        FOldBmp:=0;
        FBuffer:=NIL;
        FDInfo:=NIL;
        FDC:=0;
      end;
    end;
  end;
  {$ENDIF}



  end.
