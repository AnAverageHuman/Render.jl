#= ParseState =#
# Makes passing everything around a bit easier.
struct GCommand
    func
    args::Vector
end

mutable struct ParseState
    basename::AbstractString
    cframe::Int
    commands::Vector{GCommand}
    coords::Vector{Matrix{Float64}}
    display::IBuffer
    nframes::Int
    symtab::Dict{Symbol, Any}
    transmat::Matrix{Float64}
end
ParseState() = ParseState("", 1, Vector{GCommand}(), [Matrix(1.0I, 4, 4)], IBuffer(), 1, Dict(), Matrix(1.0I, 4, 4))

modifycoord!(ps::ParseState, trans::Matrix{Float64}) = push!(ps.coords, pop!(ps.coords) * trans)

withpm!(ps::ParseState, func, args...) = begin
    tmpp = Edges()
    func(tmpp, args...)
    drawpm!(tmpp * ps.coords[end], ps.display, VIEWVEC, CAMBIENT, LIGHTS, REFLECTION)
end

withem!(ps::ParseState, func, args...) = begin
    tmpe = Edges()
    func(tmpe, args...)
    drawem!(tmpe * ps.coords[end], ps.display, [255, 255, 255])
end

display(ps::ParseState, cmd::Cmd) = begin
    try
        open(io::IO -> dump_ppm_p6(ps.display, io), cmd, "w")
    catch e
        e isa Base.IOError || rethrow()
    end
end


#= Knobs =#
struct Knob
    sframe::Int
    eframe::Int
    svalue::Float64
    evalue::Float64
    frdata::Vector{Float64}
end
Knob(sf::Int, ef::Int, sv::Float64, ev::Float64, fr::Int) = Knob(sf, ef, sv, ev, zeros(fr))

getindex(k::Knob, i::Union{Int,UnitRange}) = k.frdata[i]


#= Miscellaneous =#
function parseNumber(tok::Token)
    return parse(Float64, untokenize(tok))
    #kind(tok) === INTEGER && return parse(Int, untokenize(tok))
    #kind(tok) === FLOAT && return parse(Float64, untokenize(tok))
end

# entry method
function renderfile(contents, lang::AbstractString="mdl")
    submod = getfield(Render, Symbol(lang))
    parser = getfield(submod, Symbol(lang, :_parser))
    execl  = getfield(submod, Symbol(lang, :_execute))

    ps = ParseState()
    ts = tokenize(contents)
    parser(ts, ps)
    execl(ps)
    ps
end
renderfile(io::IO, lang::AbstractString="mdl") = renderfile(read(io, String), lang)
renderfile(f::AbstractPath, lang::AbstractString="mdl") = open((io) -> renderfile(io, lang), f)

