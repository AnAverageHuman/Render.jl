__precompile__(true)
module Graphics

import Base: *

export
    # types
    IBuffer,
    Edges,

    # constants
    BEZSTEPS,
    CIRCSTEPS,
    HERMSTEPS,
    SPHSTEPS,
    TORUSTEPS,

    CAMBIENT,
    LIGHTS,
    REFLECTION,
    VIEWVEC,

    # methods
    dump_ppm,

    drawem!,
    drawpm!,

    addbox!,
    addcurve!,
    addedge!,
    addsphere!,
    addtorus!,

    mkrotate,
    mkscale,
    mktranslate


### source files

# constants
include("config.jl")

# represents pixels as a manipulatable array
include("display.jl")
include("line.jl")
include("edgematrix.jl")
include("matrixutil.jl")

Graphics

end

