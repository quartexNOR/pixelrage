/* Name: pixelrage, C# version
 * Written by Jon Lennart Aasenden (jonlennartaasenden.wordpress.com) 02.2011 - 04.2012
 * This unit is Buddha Ware (be kind to someone!)
 * 
 * I would like to thank Nils Haeck (http://www.simdesign.nl) for sharing his Delphi code.
 * Without his help my code could never have been ported.
 * If you use Delphi make sure to check out his native components that are outstanding.
 * 
 * I must also mention Nick Vuono, who shared his C# implementation of the Bresham line
 * algorithm (http://www.codeproject.com/KB/graphics/bresenham_revisited.aspx) covering
 * all four cardinal access points. Sadly our Delphi integer version did not convert well.
 * 
 * =========================================
 * 22.05.12 - cleanup, added to pub:svn
 * 
 * 13.03.11 - Added Push/Pop methods for ClipRect and Pen color
 * 
 * 12.03.11 - Fixed: FillRect offset by 1 pixel, dumped for/next in favour of "While"
 * 			- Fixed: Line not correctly rendered (missing endpoints)
 *
 * 
*/

#define iphone
#define debug

using System;
using System.Drawing;
using System.Collections;
#if iphone
using MonoTouch.CoreGraphics;
#endif
using System.Runtime.InteropServices;


namespace pxlrage
{
	
	//##########################################################################################################
	// Custom datatypes and structures
	//##########################################################################################################
	
	public enum TPixelFormat
	{
		pfNone=0,
#if iphone
		pf32Bit=4
#else
		pf16bit=2,
		pf24Bit=3,
		pf32Bit=4
#endif
	}
	
	/* RGB color structure */
	[StructLayout(LayoutKind.Sequential, Pack=1)] 
	public struct TRGBTriple
	{
		public byte R;
		public byte G;
		public byte B;
	}
	
	//##########################################################################################################
	// Color class
	//##########################################################################################################

	public class TColor
	{
		private byte FRed;
		private byte FGreen;
		private byte FBlue;
		private UInt32 FColor;
		
		public byte Red
		{
			get { return FRed; }
			set {
				FRed = value;
				FColor = RGBToColor(FRed,FGreen,FBlue);
			}
		}
		
		public byte Green
		{
			get { return FGreen; }
			set {
				FGreen = value;
				FColor = RGBToColor(FRed,FGreen,FBlue);
			}
		}
		
		public byte Blue
		{
			get { return FBlue; }
			set {
				FBlue = value;
				FColor = RGBToColor(FRed,FGreen,FBlue);
			}
		}
		
		public UInt32 Color
		{
			get { return FColor; }
			set { 
				FColor = value;
				ColorToRGB(FColor,out FRed,out FGreen,out FBlue);
			}
		}
		
		public class Presets
		{
			public static UInt32 Green
			{ get { return TColor.RGBToColor(0,0xff,0); } }
			
			public static UInt32 Red
			{ get { return TColor.RGBToColor(0xff,0,0); } }
			
			public static UInt32 Black
			{ get { return TColor.RGBToColor(0,0,0); } }
			
			public static UInt32 Blue
			{ get { return TColor.RGBToColor(0,0,0xff); } }			
			
			public static UInt32 White
			{ get { return TColor.RGBToColor(0xff,0xff,0xff); } }	
			
			public static UInt32 Yellow
			{ get { return TColor.RGBToColor(0xff,0xff,0); } }
			
			public static UInt32 ButtonFace
			{ get { return TColor.RGBToColor(230,230,230); } }
			
			public static UInt32 ButtonShadow
			{ get { return TColor.RGBToColor(163,163,163); } }
			
		}
		
		public static UInt32 RGBToColor(byte R, byte G, byte B)
		{ return (UInt32)(R | ( G << 8 ) | ( B << 16 ) ); }

		public static string RGBToString(byte r, byte g, byte b)
		{ return RGBToColor(r,g,b).ToString("X8"); }
		
		public static string RGBToString(TRGBTriple aColor)
		{ return RGBToColor(aColor.R,aColor.G,aColor.B).ToString("X8"); }

		public static string ColorToString(UInt32 aColor)
		{ return aColor.ToString("X8"); }
		
		public static void ColorToRGB(UInt32 aValue,out byte R, out byte G, out byte B)
		{
			R = (byte) aValue;
			G = (byte)( aValue >> 8 );
			B = (byte)( aValue >> 16 );
		}
		
		public static TRGBTriple ColorToRGB(UInt32 aColor)
		{
			TRGBTriple mTemp = new TRGBTriple();
			mTemp.R = (byte) aColor;
			mTemp.G = (byte)( aColor >> 8 );
			mTemp.B = (byte)( aColor >> 16 );
			return mTemp;
		}
		
	}
	
	//##########################################################################################################
	// Pixel Readers & Writers
	//##########################################################################################################

	/* Baseclass, Pixel Reader/Writer */
	public class TPixelIO
	{
		public unsafe virtual void WriteTo(byte* pTarget,byte R,byte G, byte B)
		{ throw new Exception("Not implemented error"); }
		
		public unsafe virtual void WriteTo(byte* pTarget,ref UInt32 ColorValue)
		{ throw new Exception("Not implemented error"); }
				
		public unsafe virtual void WriteTo(byte* pTarget, ref TRGBTriple aValue)
		{ throw new Exception("Not implemented error"); }
		
		public unsafe virtual TRGBTriple ReadFrom(byte* pSource)
		{ throw new Exception("Not implemented error"); }
		
		public unsafe virtual void WriteRep(byte* pTarget, int aCount, ref TRGBTriple aValue)
		{ throw new Exception("Not implemented error"); }
	}
	
	/* 32Bit Pixel IO class */
	public class TPixelIO32:TPixelIO
	{
		public unsafe override void WriteRep(byte* pTarget, int aCount, ref TRGBTriple aValue)
		{
			int mLongs = aCount / 8;
			int mSingles = aCount - (mLongs * 8);
			
			while (mLongs>0)
			{
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				mLongs --;
			}
			
			while (mSingles>0)
			{
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
				pTarget += 4;
				
				mSingles --;
			}
			
		}
		
		
		public unsafe override void WriteTo(byte* pTarget,byte R,byte G,byte B)
		{
				pTarget[1] = R;
				pTarget[2] = G;
				pTarget[3] = B;		
		}
				
		public unsafe override void WriteTo(byte* pTarget, ref TRGBTriple aValue)
		{
				pTarget[1] = aValue.R;
				pTarget[2] = aValue.G;
				pTarget[3] = aValue.B;
		}
		
		public unsafe override void WriteTo(byte* pTarget,ref UInt32 ColorValue)
		{
				TRGBTriple mTemp = TColor.ColorToRGB(ColorValue);
				pTarget[1] = mTemp.R;
				pTarget[2] = mTemp.G;
				pTarget[3] = mTemp.B;
		}
		
		public unsafe override TRGBTriple ReadFrom(byte* pSource)
		{ 
				TRGBTriple mRaw;
				mRaw.R = pSource[1];
				mRaw.G = pSource[2];
				mRaw.B = pSource[3];
				return mRaw;
		}
			
	}

	
	//##########################################################################################################
	// Pixmap (bitmap) surface
	//##########################################################################################################

	public class TBitmap: IDisposable
	{
		/* Class error messages */
		private const string
			ERR_PIXMAP_EMPTY = "Operation failed, pixmap not allocated error",
			ERR_PIXMAP_FAILEDALLOCATEMEMORY = "Failed to allocate memory for pixmap error",
			ERR_PIXMAP_FAILEDALLOCATECONTEXT = "Failed to allocate device context, native error",
			ERR_PIXMAP_INVALIDPIXELFORMAT = "Failed to allocate pixmap, invalid pixelformat error",
			ERR_PIXMAP_INVALIDDIMENSION = "Failed to allocate pixmap, invalid dimension error",
			ERR_PIXMAP_FAILEDRELEASE = "Failed to release pixmap, native error",
			ERR_PIXMAP_INVALIDXYPOS = "Invalid X/Y position for byte-offset error",
			ERR_PIXMAP_INVALIDROWFORSCANLINE = "Invalid scanline row, expected {0}..{1}";
				
		private IntPtr FBuffer = IntPtr.Zero;
		private int FBufferSize = 0;
		private int FWidth  = 0;
		private int FHeight = 0;
		private int FScanLine = 0;
		private int FPxSize = 0;
		private TPixelIO FIO;		
		private Rectangle FBounds;
		private Rectangle FClipRect;
		private TPixelFormat FFormat = TPixelFormat.pfNone;
		private TColor FPen;
		private Point FCursor;
#if iphone
		private CGBitmapContext FContext = null;
#endif
		
		private Stack FClipStack = null;
		private Stack FColorStack = null;
		
		
		public int PixelSize
		{ get { return FPxSize; } }
		
		public TPixelFormat PixelFormat
		{ get { return FFormat; } }
		
		public int Width
		{ get { return FWidth; } }
		
		public int Height
		{ get { return FHeight; } }
		
		public bool Empty
		{ get { return FBuffer==IntPtr.Zero; } }
		
		public int ScanLineSize
		{ get { return FScanLine; } }

		public Rectangle ClipRect
		{
			get { return FClipRect; }
			set { FClipRect = AdjustToBounds(ClipRect); }
		}
		
		public Rectangle BoundsRect
		{ get { return FBounds; } }
		
		public TColor Pen
		{ 	get { return FPen; }
			set { FPen.Color = Pen.Color; }
		}
		

		/* Constructor */
		public TBitmap()
		{
			FPen = new TColor();
			FBounds = Rectangle.Empty;
			FClipRect = Rectangle.Empty;
			FCursor = Point.Empty;
			FClipStack = new System.Collections.Stack();
			FColorStack = new System.Collections.Stack();
		}
		
		/* Destructor */
		~TBitmap()
		{ Dispose(false); }
		
		/* IDisposable::Dispose */
		public void Dispose()
		{
			Dispose(true);
			GC.SuppressFinalize(this);
		}
		
		/* IDisposable::Dispose */
		protected virtual void Dispose(bool disposing)
		{
			if (disposing)
			{
				//Release normal objects here
				FClipStack = null;
				FColorStack = null;
			}
			
			/* Any native data allocated? */
			if (Empty != true)
			{
				#if debug
				Console.WriteLine("Releasing pixmap data");
				#endif	
				Release();
			}
		}

		public unsafe void Allocate(int aWidth, int aHeight, TPixelFormat aFormat)
		{
			/* Check if a buffer is already allocated.
			 	Release it at once if this is the case */
			if (Empty !=true)
				Release();
			
			/* Check With & Height parameters */
			if (aWidth>0 && aHeight>0)
			{
				/* Make sure pixelformat is acceptable */
				if (aFormat != TPixelFormat.pfNone)
				{
					
					FPxSize = Convert.ToInt32(aFormat);
					
					/*	First, calculate the bytesize of a single row, this is called
					 	a scanline's stride, because it's rounded up to the nearest 4 byte
					 	boundary. Most developers avoid this and as a result their
					 	applications will fail because of memory fragmentation. This is
					 	warned about by both Microsoft and Apple in both their SDk's
					 	documentation on allocating memory for pixels. */
					FScanLine = CalcStrideAlign(aWidth, FPxSize, 4);
					
					/*	Calculate the total number of bytes req. for the pixmap */
					FBufferSize = FScanLine * aHeight;
					
					/* 	The next section of code has to be marked "unsafe" because we allocate
					 	our memory buffer directly from the system. It's actually just as safe
					 	as anything else if you know what you are doing. */
					try {
						FBuffer=Marshal.AllocHGlobal(FBufferSize);
					} catch (Exception e) {
						FBufferSize=0;
						FScanLine=0;
						FPxSize=0;
						throw new Exception(ERR_PIXMAP_FAILEDALLOCATEMEMORY,e);
					}
					
					/* Allocate native device context for iOS */
#if iphone
					try {							
				 		FContext = new CGBitmapContext(FBuffer,aWidth,
						               aHeight,8,FScanLine,
				                       CGColorSpace.CreateDeviceRGB(),
						               CGImageAlphaInfo.NoneSkipFirst);						
					} catch (Exception e) {
						/* Release memory */
						Marshal.FreeHGlobal(FBuffer);
						FBufferSize=0;
						FPxSize=0;
						throw new Exception(ERR_PIXMAP_FAILEDALLOCATECONTEXT,e);
					}
#endif

					/* keep properties */
					FWidth = aWidth;
					FHeight = aHeight;
					FFormat = aFormat;		
					FBounds = new Rectangle(0,0,FWidth-1,FHeight-1);
					FClipRect = FBounds;
					
					/* create the correct PIXEL IO driver */
					switch (FFormat)
					{
#if iphone
					case TPixelFormat.pf32Bit:
						FIO = new TPixelIO32();
						break;
#else									
					case TPixelFormat.pf16bit:
						FIO = new TPixelIO16();
						break;
					case TPixelFormat.pf24Bit:
						FIO = new TPixelIO24();
						break;
					case TPixelFormat.pf32Bit:
						FIO = new TPixelIO32();
						break;
#endif
					}

#if iphone
					/* Set context properties, ignore possible OS errors at this point */
					try {
						FContext.InterpolationQuality = CGInterpolationQuality.None;
						FContext.SetShouldAntialias(false);
					} catch {
						return;
					}
#endif
				} else
				throw new Exception(ERR_PIXMAP_INVALIDPIXELFORMAT);
			} else
			throw new Exception(ERR_PIXMAP_INVALIDDIMENSION);
		}
		
		public unsafe void Release()
		{
			/* Check if pixelbuffer is empty */
			if (FBuffer != IntPtr.Zero)
			{
				try
				{
					try {
						/* Release allocated memory block */
						Marshal.FreeHGlobal(FBuffer);
					} catch (Exception e) {
						throw new Exception(ERR_PIXMAP_FAILEDRELEASE,e);
					}
				} finally {
					FContext.Dispose();
					FContext = null;
					FIO = null;
					
					/* reset format values */
		  			FBuffer = IntPtr.Zero;
		  			FBufferSize = 0;
		  			FWidth  = 0;
		 			FHeight = 0;
					FScanLine = 0;
					FPxSize =0;
					FCursor = Point.Empty;
					FFormat = TPixelFormat.pfNone;
					FClipStack.Clear();
					FColorStack.Clear();
				}
			}
		}
		
		public int PixelOffset(int xpos, int ypos)
		{	
			if (FBuffer != IntPtr.Zero)
			{		
				if (xpos>=0 && xpos<FWidth
				&& ypos>=0 && ypos<FHeight)
				{ return (ypos * FScanLine) + (xpos * FPxSize); } else
				throw new Exception(ERR_PIXMAP_INVALIDXYPOS);
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		public unsafe byte* ScanLine(int Row)
		{
			if (FBuffer != IntPtr.Zero)
			{		
				if (Row>=0 && Row<FHeight)
				{
					byte* mTemp = (byte*)FBuffer + (Row * FScanLine);
					return mTemp;
				} else
				throw new Exception(string.Format(ERR_PIXMAP_INVALIDROWFORSCANLINE,0,FHeight-1));
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		public unsafe byte* PixelAddr(int Col,int Row)
		{
			if (FBuffer != IntPtr.Zero)
			{
				if (Col >= 0 && Col <FWidth && Row>=0 && Row < FHeight)
				{
					byte* mTemp = (byte*)FBuffer + (Row * FScanLine) + (Col * FPxSize);
					return mTemp;
				} else
				throw new Exception(ERR_PIXMAP_INVALIDXYPOS);
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		private int CalcStrideAlign(int aValue, int elementSize, int alignsize)
		{
			int ftemp = aValue * elementSize;
			if ( (ftemp % alignsize) >0 )
			{ return (ftemp + alignsize) - (ftemp % alignsize); } else
			return ftemp;
		}

		public Rectangle AdjustToBounds(Rectangle aRect)
		{
			if (FBounds != Rectangle.Empty)
			{
				int dx, dy, dx2, dy2;
				if (aRect.Left<0) { dx=0; } else { dx=aRect.Left; }
				if (aRect.Top<0) { dy=0; } else { dy=aRect.Top; }
				if (aRect.Right>FBounds.Right) { dx2=FBounds.Right; } else { dx2=aRect.Right; }
				if (aRect.Bottom>FBounds.Bottom) { dy2=FBounds.Bottom; } else { dy2=aRect.Bottom; }
				return new Rectangle(dx,dy,(dx2-dx)+1,(dy2-dy)+1);
			} else
			return Rectangle.Empty;
		}

		public Rectangle AdjustToClipRect(Rectangle aRect)
		{
			if (FClipRect != Rectangle.Empty)
			{
				int dx, dy, dx2, dy2;
				if (aRect.Left<FClipRect.Left) { dx=FClipRect.Left; } else { dx=aRect.Left; }
				if (aRect.Top<FClipRect.Top) { dy=FClipRect.Top; } else { dy=aRect.Top; }
				if (aRect.Right>FClipRect.Right) { dx2=FClipRect.Right; } else { dx2=aRect.Right; }
				if (aRect.Bottom>FClipRect.Bottom) { dy2=FClipRect.Bottom; } else { dy2=aRect.Bottom; }			
				return new Rectangle(dx,dy,(dx2-dx)+1,(dy2-dy)+1);
			} else
			return Rectangle.Empty;
		}
		
		public void PushClipRect(Rectangle aNewClipRect)
		{
			if (FBuffer != IntPtr.Zero)
			{
				FClipStack.Push(FClipRect);
				FClipRect = this.AdjustToBounds(aNewClipRect);
			}
		}

		public void PushClipRect()
		{
			if (FBuffer != IntPtr.Zero)
			{ FClipStack.Push(FClipRect); }
		}
		
		public void PopClipRect()
		{
			if (FBuffer != IntPtr.Zero)
			{
				if (FClipStack.Count >0)
				FClipRect = (Rectangle)FClipStack.Pop();
			}
		}
		
		public void PushPenColor(UInt32 aNewColor)
		{
			if (FBuffer != IntPtr.Zero)
			{
				FColorStack.Push(FPen.Color);
				FPen.Color = aNewColor;
			}
		}
		
		public void PushPenColor()
		{
			if (FBuffer != IntPtr.Zero)
			{ FColorStack.Push(FPen.Color); }
		}
		
		public void PopPenColor()
		{
			if (FBuffer != IntPtr.Zero)
			{
				if (FColorStack.Count>0)
				Pen.Color = (UInt32)FColorStack.Pop();
			}
		}
		
		public unsafe void Cls()
		{ Cls(Pen.Color); }
		
		public unsafe void Cls(UInt32 aColor)
		{
			if (FBuffer != IntPtr.Zero)
			{
				TRGBTriple mTemp = TColor.ColorToRGB(aColor);
				
				/* Get a byte-array pointer to our buffer */
				byte* bufPtr = (byte*)((void*)FBuffer);				
				
				/* for each row in the bitmap */
				int y=0;
				while (y<FHeight)
				{			
					/* quickly fill enture scanline */
					FIO.WriteRep(bufPtr,FWidth,ref mTemp);
					
					/* update pointer for next scanline */
					bufPtr+=FScanLine;
					y++;
				}

			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}

		private void __SwapColors(ref UInt32 afirst, ref UInt32 aSecond)
		{
			UInt32 mTemp = afirst;
			afirst = aSecond;
			aSecond = mTemp;
		}
		
		private void __SwapInt(ref Int32 afirst, ref Int32 aSecond)
		{
			Int32 mTemp = afirst;
			afirst = aSecond;
			aSecond = mTemp;
		}

		public void Frame3d(Rectangle aValue,UInt32 aLight,UInt32 aDark)
		{ Frame3d(aValue,aLight,aDark,true); }

		public void Frame3d(Rectangle aValue,UInt32 aLight,UInt32 aDark,bool aRaised)
		{
			if (aValue.IsEmpty != true)
			{
				if (aRaised == false)
					__SwapColors(ref aLight,ref aDark);
				
				Line(aValue.Left,aValue.Bottom,aValue.Left,aValue.Top,aLight);
				Line(aValue.Left+1,aValue.Top,aValue.Right,aValue.Top,aLight);
				
				Line(aValue.Left+1,aValue.Bottom,aValue.Right,aValue.Bottom,aDark);
				Line(aValue.Right,aValue.Bottom-1,aValue.Right,aValue.Top+1,aDark);
			}
		}
		
		public void Frame3d(Rectangle aValue,UInt32 aLight,UInt32 aDark,UInt32 aFillColor,bool aRaised)
		{
			if (aValue.IsEmpty != true)
			{
				Frame3d(aValue,aLight,aDark,aRaised);
				aValue.Inflate(-2,-2);
				
				if (aValue.IsEmpty != true)
				RectFill(aValue,aFillColor);
			}
		}
		
		public void RectOutline(Rectangle aValue)
		{ RectOutline(aValue, Pen.Color); }
		
		public void RectOutline(Rectangle aValue, UInt32 aColor)
		{
			Line(aValue.Left,aValue.Top,aValue.Right,aValue.Top);
			Line(aValue.Right,aValue.Top,aValue.Right,aValue.Bottom);
			Line(aValue.Left,aValue.Top,aValue.Left,aValue.Bottom);
			Line(aValue.Left,aValue.Bottom,aValue.Right,aValue.Bottom);
		}

		public unsafe void RectFill(Rectangle Value, UInt32 aColor)
		{
			if (FBuffer != IntPtr.Zero)
			{				
				Value = AdjustToClipRect(Value);				
				if (Value.IsEmpty != true)
				{
					/* get an RGB structure */
					TRGBTriple mTemp = TColor.ColorToRGB(aColor);
					
					/* Get a byte-array pointer to our buffer */
					byte* bufPtr = (byte*)((void*)FBuffer);					
			
					int y = Value.Top;
					while (y < Value.Bottom)
					{
						byte* pTarget = bufPtr;
						pTarget += ( (y * FScanLine) + (Value.Left * FPxSize) );

						FIO.WriteRep(pTarget,Value.Width,ref mTemp);

						y++;
					}
				}
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		public void PolyOutline(Point[] aPoints)
		{ PolyOutline(aPoints,Pen.Color); }
		
		public void PolyOutline(Point[] aPoints,UInt32 aColor)
		{			
			if (aPoints.Length >1)
			{
				UInt32 mOldColor = Pen.Color;
				Pen.Color = aColor;
				for (int x=0;x<aPoints.Length;x++)
				{
					if (x==0)
					{ MoveTo(aPoints[aPoints.GetLowerBound(0)]); } else
					{ LineTo(aPoints[aPoints.GetLowerBound(0) + x]); }
				}
				Pen.Color = mOldColor;
			}
		}
		
		public void RectFill(Rectangle aValue)
		{ RectFill(aValue,Pen.Color); }
		
		public unsafe void SetPixel(int Left,int Top)
		{ SetPixel(Left,Top,Pen.Color); }
		
		public unsafe void SetPixel(int Left,int Top,UInt32 aColor)
		{
			if (FBuffer != IntPtr.Zero)
			{			
				if (FClipRect.Contains(Left,Top))
				{
					TRGBTriple mTemp = TColor.ColorToRGB(aColor);
					
					/* Get a byte-array pointer to our buffer */
					byte* bufPtr = (byte*)((void*)FBuffer);
					
					/* Adjust to get pixel adress */
					bufPtr += ( (Top * FScanLine) + (Left * FPxSize) );
										
					/* Write pixel through driver */
					FIO.WriteTo(bufPtr,ref mTemp);
					
					FCursor.X = Left;
					FCursor.Y = Top;
				}
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}

		public void MoveTo(Point aPos)
		{
			if (FBuffer != IntPtr.Zero)
			{ FCursor = aPos; } else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		public void MoveTo(int aLeft, int aTop)
		{
			if (FBuffer != IntPtr.Zero)
			{ FCursor = new Point(aLeft,aTop); } else
			throw new Exception(ERR_PIXMAP_EMPTY);
		}
		
		public void LineTo(int Left,int Top)
		{ Line(FCursor.X,FCursor.Y,Left,Top); }
		
		public void LineTo(Point aPos)
		{ Line(FCursor.X,FCursor.Y,aPos.X,aPos.Y); }
		
		public void Line(int x1,int y1,int x2,int y2)
		{ Line(new Point(x1,y1),new Point(x2,y2), Pen.Color); }

		public void Line(int x1, int y1, int x2, int y2, UInt32 aColor)
		{ Line(new Point(x1,y1),new Point(x2,y2), aColor); }
		
		public void Line(Point begin, Point end)
		{ Line(begin,end,Pen.Color); }

		
		/* Adapted from Nick Vuono's C# implementation of the bresham method */		
    	public void Line(Point begin, Point end, UInt32 aColor)
        {			
			if (FBuffer != IntPtr.Zero)
			{
	            if (Math.Abs(end.Y - begin.Y) < Math.Abs(end.X - begin.X))
	            {
	                if (end.X >= begin.X)
	                {
			            Point nextPoint = begin;
			            int deltax = end.X - begin.X;
			            int deltay = end.Y - begin.Y;
			            int error = deltax / 2;
			            int ystep = 1;
						
			            if (end.Y < begin.Y)  { ystep = -1; } else
			            if (end.Y == begin.Y) { ystep = 0;  }
			
			            while (nextPoint.X < end.X)
			            {
			                if (nextPoint != begin && nextPoint != end)
							SetPixel(nextPoint.X,nextPoint.Y,aColor);
			                nextPoint.X++;
			
			                error -= deltay;
			                if (error < 0)
			                {
			                    nextPoint.Y += ystep;
			                    error += deltax;
			                }
			            }
	                }
	                else
	                {
			            Point nextPoint = begin;
			            int deltax = end.X - begin.X;
			            int deltay = end.Y - begin.Y;
			            int error = deltax / 2;
			            int ystep = 1;
			
			            if (end.Y < begin.Y)  { ystep = -1; } else
			            if (end.Y == begin.Y) { ystep = 0; }
			
			            while (nextPoint.X > end.X)
			            {
			                if (nextPoint != begin && nextPoint != end)
							SetPixel(nextPoint.X,nextPoint.Y,aColor);
			                nextPoint.X--;
			
			                error += deltay;
			                if (error < 0)
			                {
			                    nextPoint.Y += ystep;
			                    error -= deltax;
			                }
			            }
	                }
	            }
	            else
	            {
	                if (end.Y >= begin.Y)
	                {
			            Point nextPoint = begin;
			            int deltax = Math.Abs(end.X - begin.X);
			            int deltay = end.Y - begin.Y;
			            int error = Math.Abs(deltax / 2);
			            int xstep = 1;
			
			            if (end.X < begin.X)  { xstep = -1; } else
			            if (end.X == begin.X) { xstep = 0; }
			
			            while (nextPoint.Y < end.Y)
			            {
			                if (nextPoint != begin && nextPoint != end)
							SetPixel(nextPoint.X,nextPoint.Y,aColor);
			                nextPoint.Y++;
			
			                error -= deltax;
			                if (error < 0)
			                {
			                    nextPoint.X += xstep;
			                    error += deltay;
			                }
			            }
	                }
	                else
	                {
			            Point nextPoint = begin;
			            int deltax = end.X - begin.X;
			            int deltay = end.Y - begin.Y;
			            int error = deltax / 2;
			            int xstep = 1;
			
			            if (end.X < begin.X)  { xstep = -1; } else
			            if (end.X == begin.X) { xstep = 0; }

			            while (nextPoint.Y > end.Y)
			            {
			                if (nextPoint != begin && nextPoint != end)
							SetPixel(nextPoint.X,nextPoint.Y,aColor);
			                nextPoint.Y--;
			
			                error += deltax;
			                if (error < 0)
			                {
			                    nextPoint.X += xstep;
			                    error -= deltay;
			                }
			            }
	                }

				/* Now close endpoints */
				SetPixel(begin.X,begin.Y,aColor);
				SetPixel(end.X,end.Y,aColor);
									
	            }
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);	
        }
		
		public void CircleOutline(Rectangle aRect)
		{
			CircleOutline(new Point(aRect.Left + (aRect.Width / 2), aRect.Top + (aRect.Height / 2)),Math.Min(aRect.Width,aRect.Height) / 2);
		}
		
		/* Adapted from Nick Vuono's C# implementation of the bresham algorythm */
        public void CircleOutline(Point midpoint, int radius)
        {
			if (FBuffer != IntPtr.Zero)
			{
	            Point returnPoint = new Point();
	            int f = 1 - radius;
	            int ddF_x = 1;
	            int ddF_y = -2 * radius;
	            int x = 0;
	            int y = radius;
	
	            returnPoint.X = midpoint.X;
	            returnPoint.Y = midpoint.Y + radius;
				SetPixel(returnPoint.X,returnPoint.Y);
				
	            returnPoint.Y = midpoint.Y - radius;
				SetPixel(returnPoint.X,returnPoint.Y);
	            
				returnPoint.X = midpoint.X + radius;
	            returnPoint.Y = midpoint.Y;
				SetPixel(returnPoint.X,returnPoint.Y);
	            
				returnPoint.X = midpoint.X - radius;
				SetPixel(returnPoint.X,returnPoint.Y);
	
	            while (x < y)
	            {
	                if (f >= 0)
	                {
	                    y--;
	                    ddF_y += 2;
	                    f += ddF_y;
	                }
	                x++;
	                ddF_x += 2;
	                f += ddF_x;
	                returnPoint.X = midpoint.X + x;
	                returnPoint.Y = midpoint.Y + y;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X - x;
	                returnPoint.Y = midpoint.Y + y;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X + x;
	                returnPoint.Y = midpoint.Y - y;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X - x;
	                returnPoint.Y = midpoint.Y - y;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X + y;
	                returnPoint.Y = midpoint.Y + x;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X - y;
	                returnPoint.Y = midpoint.Y + x;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X + y;
	                returnPoint.Y = midpoint.Y - x;
					SetPixel(returnPoint.X,returnPoint.Y);
					
	                returnPoint.X = midpoint.X - y;
	                returnPoint.Y = midpoint.Y - x;
					SetPixel(returnPoint.X,returnPoint.Y);
	            }
			} else
			throw new Exception(ERR_PIXMAP_EMPTY);
        }
		
	public void EllipseOutline(Rectangle aRect)
	{
		if (aRect.IsEmpty != true && aRect.Width>2 && aRect.Height>2)
		{
			int wd = aRect.Width / 2;
			int hd = aRect.Height / 2;
			int dx = aRect.Left + wd;
			int dy = aRect.Top + hd;				
			EllipseOutline(dx,dy,wd,hd,Pen.Color);
		}
	}
		
	public void EllipseOutline(Rectangle aRect,UInt32 aColor)
	{
		if (aRect.IsEmpty != true && aRect.Width>2 && aRect.Height>2)
		{
			int wd = aRect.Width / 2;
			int hd = aRect.Height / 2;
			int dx = aRect.Left + wd;
			int dy = aRect.Top + hd;				
			EllipseOutline(dx,dy,wd,hd,aColor);
		}
	}
	
	public void EllipseOutline(int Left, int Top, int Right, int Bottom)
	{
		int wd = (Right-Left) + 1;
		int hd = (Bottom-Top) + 1;
		int qx = Left + (wd / 2);
		int qy = Top + (hd / 2);
		EllipseOutline(Left,Top,qx,qy,Pen.Color); 		
	}

	public void EllipseOutline(int x1, int y1, int RadX, int RadY, UInt32 Color)
	{
		if (FBuffer != IntPtr.Zero)
		{
			if (RadX >2 && RadY>2)
			{
				int x, y, XChange, YChange, EllipseError, TwoASquare, TwoBSquare, StoppingX, StoppingY;
				TwoASquare = 2 * RadX * RadX;
				TwoBSquare = 2 * RadY * RadY;
				x = RadX;
				y = 0;
				XChange = RadY * RadY * (1 - 2 * RadX);
				YChange = RadX * RadX;
				EllipseError = 0;
				StoppingX = TwoBSquare * RadX;
				StoppingY = 0;
				while( StoppingX >= StoppingY)
				{
					SetPixel(x1 + x,y1 + y,Color);
					SetPixel(x1 - x,y1 + y,Color);
					SetPixel(x1 - x,y1 - y,Color);
					SetPixel(x1 + x,y1 - y,Color);
					y++;
					StoppingY += TwoASquare;
					EllipseError += YChange;
					YChange += TwoASquare;
					if( ( 2 * EllipseError + XChange) > 0 )
					{
						x--;
						StoppingX -= TwoBSquare;
						EllipseError += XChange;
						XChange += TwoBSquare;
					}
				}
					
				x = 0;
				y = RadY;
				XChange = RadY * RadY;
				YChange = RadX * RadX * (1 - 2 * RadY);
				EllipseError = 0;
				StoppingX = 0;
				StoppingY = TwoASquare * RadY;
				while (StoppingX <= StoppingY)
				{				
					SetPixel(x1 - x,y1 - y,Color);
					SetPixel(x1 + x,y1 - y,Color);
					SetPixel(x1 + x,y1 + y,Color);
					SetPixel(x1 - x,y1 + y,Color);			
					x++;
					StoppingX += TwoBSquare;
					EllipseError += XChange;
					XChange += TwoBSquare;
					if( (2 * EllipseError + YChange) > 0)
					{
						y--;
						StoppingY -= TwoASquare;
						EllipseError += YChange;
						YChange += TwoASquare;
					}
				}
			}
		} else
		throw new Exception(ERR_PIXMAP_EMPTY);
	}

		
		
#if iphone
		public CGImage toImage()
		{ return FContext.ToImage(); }
#endif
		
	}

}
