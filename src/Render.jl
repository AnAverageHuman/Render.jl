__precompile__(true)
module Render

using ElasticArrays
using JuliaParser.Diagnostics: Incomplete, diag
using JuliaParser.Lexer
using JuliaParser.Lexer: TokenStream, eof, here
using RoundingIntegers

import Base: *, getindex, size

export
    # constants
    BEZSTEPS,
    CIRCSTEPS,
    HERMSTEPS,
    SPHSTEPS,
    TORUSTEPS,

    # methods
    dump_ppm_p3,
    dump_ppm_p6,

    addbox!,
    addcurve!,
    addedge!,
    addsphere!,
    addtorus!,

    mkrotate,
    mkscale,
    mktranslate,

    renderfile


### source files

# constants
include("config.jl")

# represents pixels as a manipulatable array
include("display.jl")
include("line.jl")
include("edgematrix.jl")
include("matrixutil.jl")

# parsers
include("parser.jl")

include(joinpath("langs", "mdl.jl"))
using .mdl: mdl_execute, mdl_parser


Render

end

