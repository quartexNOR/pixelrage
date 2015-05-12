PXR is a slim, easy to use and innovative graphics library that represents a foundation for further, more advanced libraries. As such SL does not implement everything under the sun, but aims to provide a rock-solid basis that can be easily extended. By default the unit implements a RAW surface, which is basically
a surface held in RAM without any device context. It also
provides a Windows DIB implementation that does have a context and can thus be used with blitting and Delphi canvas operations.

PXR is not about the latest cool feature. It is about providing a platform independent foundation, assembly free, that other more advanced libraries can be based.

**Features**

8, 15, 16, 24 and 32 bit pixelbuffers. Fast native blitter between pixel formats (e.g copy from 32bpp -> 8bpp). Palette handling. Clipping. Basic primitives (circle, ellipse, rectangle). Fill mechanism. Alpha blending. Transparency. DIB implementation. UNI implementation.

Dependencies: Byterage
http://code.google.com/p/byterage/