# Pixel Maker

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


# License

I'm not accepting pull requests, but the code is available publicaly as I think
it is valuable informations for people who are looking to own the graphical
stack of their software. The licence is "do what you want with it, but it could
be cool to have a little note somewhere that you got inspire by it".

# Thanks

A special thank goes to Stefan, he originally wrote the first version, which
goes more into Metal-way kind of API, with OpenGL for Windows instead of
DirectX. If you want to follow him and his projects []().

The article written by Sebastian Aaltonen, [No Graphics
API](https://www.sebastianaaltonen.com/blog/no-graphics-api) opened my eyes on
my things, and drive me towards this similar design (but I'm a bit blocked by
DX11 and not ready to move on).
