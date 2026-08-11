# Pixel Maker

_I'm not accepting pull requests, but the code is available publicly as I think
it is valuable information for people who are looking to own the graphical
stack of their software._

This code is a thin layer on top of Metal and DirectX 11 APIs. The goal of this
module, is to let us write graphics code once, while keeping some sort of
simplicity in the API. Currently it powered all my projects that plays with
graphics.

I liked the "immediate" feeling of the DX11 API, its inner state machine reduce
boilerplate and goes more in my programming style. So internally, we create
pipeline states (PSO) on the fly and then cached them in a lookup table. If you
have many PSOs, this could have some incidence on the first few frames, but I
think it's manageable with relatively simple techniques.

We can load Slang written shaders as well, and you'll get binding informations
alongside the corresponding shader program; we use Slang reflection system to
find the name of bindings, slot numbers, and types.

# How to

- explain libslang etc should sit next to executable.
- add Slang LICENSE as well.


# Thanks

A special thank goes to Stefan, he wrote the first version, which was more into
Metal-way kind of API, with OpenGL for Windows instead of DirectX. Since then,
this module has been largely rewrite, but still he was a great inspiration
behind that []().

The article written by Sebastian Aaltonen, [No Graphics
API](https://www.sebastianaaltonen.com/blog/no-graphics-api) opened my eyes on
my things, and drive me towards this similar design (but I'm a bit blocked by
DX11 and not ready to move on).

# License

MIT License

Copyright (c) 2026 Alexandre Chêne

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

