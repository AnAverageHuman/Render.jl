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
ParseState() = ParseState("", 1, Vector{GCommand}(), [eye(4)], IBuffer(), 1, Dict(), eye(4))

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
        e isa Base.UVError || rethrow()
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


# extensions to JuliaParser.Lexer
function peekchars(io::IO, count::Int)
    mark(io)
    ret = String(read(io, count))
    reset(io)
    return ret
end
peekchars(ts::TokenStream, count::Int) = peekchars(ts.io, count)

peekcomment(ts::TokenStream, cm::AbstractString) = peekchars(ts, length(cm)) == cm

function skipcomment(ts::TokenStream, cm::AbstractString)
    @assert peekcomment(ts, cm)
    Lexer.skip_to_eol(ts)
end

function skipws_and_comments(ts::TokenStream, cm::AbstractString)
    while ! eof(ts)
        Lexer.skipws(ts, true)
        peekcomment(ts, cm) || break
        skipcomment(ts, cm)
    end
end

function require_token(ts::TokenStream, nextt=Lexer.next_token)
    if ts.putback !== nothing
        t = ts.putback
    elseif ts.lasttoken !== nothing
        t = ts.lasttoken
    else
        t = nextt(ts)
    end
    eof(t) && throw(Incomplete(:other, diag(here(ts), "incomplete: premature end of input")))
    while Lexer.isnewline(t)
        Lexer.take_token(ts)
        t = nextt(ts)
    end
    eof(t) && throw(Incomplete(:other, diag(here(ts), "incomplete: premature end of input")))
    ts.putback === nothing && Lexer.set_token!(ts, t)
    return t
end


# entry method
function renderfile(contents::Vector{String}, lang::AbstractString="mdl")
    submod = getfield(Render, Symbol(lang))
    parser = getfield(submod, Symbol(lang, :_parser))
    execl  = getfield(submod, Symbol(lang, :_execute))

    ps = ParseState()
    for line in contents
        ts = TokenStream{Lexer.SourceLocToken}(line)
        parser(ts, ps)
    end
    execl(ps)
    ps
end
renderfile(io::IO, lang::AbstractString="mdl") = renderfile(readlines(io), lang)

