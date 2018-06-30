__precompile__(true)
module mdl

using JuliaParser.Diagnostics
using JuliaParser.Lexer
using JuliaParser.Lexer: @tok, TokenStream, eof, eof_token, make_token, peekchar
using JuliaParser.Tokens: ¬, √
using Graphics
using Graphics: GCommand, Knob, ParseState, modifycoord!, withem!, withpm!

export mdl_execute, mdl_parser

COMMENT = "//"
peekcomment(ts::TokenStream) = Graphics.peekcomment(ts, COMMENT)


function next_token{T}(ts::TokenStream{T})
    ts.ateof && return eof_token(ts)
    tmp = Lexer.skipws(ts, false)
    eof(ts) && return eof_token(ts)
    ts.isspace = tmp

    while ! eof(ts)
        peekcomment(ts) && skipcomment(ts, COMMENT)
        c = peekchar(ts)
        if eof(c)
            ts.ateof = true
            return eof_token(T)
        elseif c === ' ' || c === '\t'
            Lexer.skip(ts, 1)
            continue
        elseif c == '\r'
            Lexer.skip(ts, 1)
            peekchar(ts) === '\n' || throw(Lexer.here(ts),
                                           "'\\r' not followed by '\\n' is invalid")
            continue
        elseif Lexer.isnewline(c)
            return @tok Lexer.readchar(ts)
        elseif isdigit(c)
            return Lexer.read_number(ts, false, false)
        elseif c === '-'
            Lexer.skip(ts, 1)
            d = peekchar(ts)
            return isdigit(d) ? Lexer.read_number(ts, d === '.', true) : @tok :(-)
        elseif c === '.'
            Lexer.skip(ts, 1)
            return isdigit(peekchar(ts)) ? Lexer.read_number(ts, true, false) : @tok :(.)
        elseif Lexer.is_identifier_start_char(c)
            return @tok Lexer.accum_julia_symbol(ts, c)
        else
            @assert Lexer.readchar(ts) === c
            throw(Diagnostics.diag(Lexer.here(ts), "invalid character \"$c\""))
        end
    end

    ts.ateof = true
    return eof_token(ts)
end

# simple substitution
const F64 = Float64

# MDL commands
mdlpush(ps::ParseState) = push!(ps.coords, ps.coords[end])
mdlpop(ps::ParseState)  = length(ps.coords) > 1 && pop!(ps.coords)

knobworks(ps, k, thing) = k === nothing ? thing : thing * ps.symtab[k][ps.cframe]

mdlmove(ps::ParseState, x::F64, y::F64, z::F64, knob = nothing) = begin
    modifycoord!(ps, mktranslate(knobworks(ps, knob, [x, y, z])))
end

mdlscale(ps::ParseState, x::F64, y::F64, z::F64, knob = nothing) = begin
    modifycoord!(ps, mkscale(knobworks(ps, knob, [x, y, z])))
end

mdlrotate(ps::ParseState, dir::Symbol, d::F64, knob = nothing) = begin
    modifycoord!(ps, mkrotate(knobworks(ps, knob, d), dir))
end

# optional not at end
mdlsphere(ps::ParseState, cons, x::F64, y::F64, z::F64, r::F64, coord = nothing) = begin
    withpm!(ps, addsphere!, [x, y, z], r, SPHSTEPS)
end
mdlsphere(ps::ParseState, x::F64, y::F64, z::F64, r::F64, coord = nothing) = mdlsphere(ps, nothing, x, y, z, r, coord)

mdltorus(ps::ParseState, cons, x::F64, y::F64, z::F64, r1::F64, r2::F64, coord = nothing) = begin
    withpm!(ps, addtorus!, [x, y, z], r1, r2, TORUSTEPS)
end
mdltorus(ps::ParseState, x::F64, y::F64, z::F64, r1::F64, r2::F64, coord = nothing) = mdltorus(ps, nothing, x, y, z, r1, r2, coord)

mdlbox(ps::ParseState, cons, x1::F64, y1::F64, z1::F64, x2::F64, y2::F64, z2::F64, coord = nothing) = begin
    withpm!(ps, addbox!, [x1, y1, z1], x2, y2, z2)
end
mdlbox(ps::ParseState, x1::F64, y1::F64, z1::F64, x2::F64, y2::F64, z2::F64, coord = nothing) = mdlbox(ps, nothing, x1, y1, z1, x2, y2, z2, coord)

# there should be a cleaner way to do this
mdlline(ps::ParseState, cons, x1::F64, y1::F64, z1::F64, coord1::Symbol, x2::F64, y2::F64, z2::F64, coord2 = nothing) = begin
    withem!(ps, addedge!, [x1, y1, z1], [x2, y2, z2])
end
mdlline(ps::ParseState, x1::F64, y1::F64, z1::F64, coord1::Symbol, x2::F64, y2::F64, z2::F64, coord2 = nothing) = mdlline(ps, nothing, x1, y1, z1, coord1, x2, y2, z2, coord2)
mdlline(ps::ParseState, cons::Symbol, x1::F64, y1::F64, z1::F64, x2::F64, y2::F64, z2::F64, coord2 = nothing) = mdlline(ps, cons, x1, y1, z1, nothing, x2, y2, z2, coord2)
mdlline(ps::ParseState, x1::F64, y1::F64, z1::F64, x2::F64, y2::F64, z2::F64, coord2 = nothing) = mdlline(ps, nothing, x1, y1, z1, nothing, x2, y2, z2, coord2)

mdlbasename(ps::ParseState, bn...) = ps.basename = string(bn...)
mdlframes(ps::ParseState, f::F64) = ps.nframes = Int(f)

mdlvary(ps::ParseState, knob::Symbol, sf, ef, sv::F64, ev::F64) = begin
    sf = Int(sf)
    ef = Int(ef)
    ps.symtab[knob] = get(ps.symtab, knob, Knob(sf, ef, sv, ev, ps.nframes))
    ps.symtab[knob].frdata[sf:ef - 1] = [sv + (ev - sv) / (ef - sf) * i for i in 1:(ef - sf)]
end

mdlsave(ps::ParseState, fn...) = Graphics.display(ps, `convert - $(string(fn...))`)
mdldisplay(ps::ParseState) = begin
    if ps.nframes > 1
        run(`animate -delay $(Graphics.ANIM_DELAY) "$tmp/$(ps.basename)*"`)
    else
        Graphics.display(ps, `display`)
    end
end


function mdl_parser(ts::TokenStream, ps::ParseState)
    Graphics.skipws_and_comments(ts, COMMENT)
    eof(ts) && return

    args = Vector{Any}()
    t = Graphics.require_token(ts, next_token)
    command = nothing

    try
        command = getfield(mdl, Symbol(:mdl, ¬t))
    catch UndefVarError
        error("$(¬t) is not a valid MDL command")
    end

    while ! eof(ts)
        x = next_token(ts)
        push!(args, ¬x isa Number ? float(¬x) : ¬x)
    end

    push!(ps.commands, GCommand(command, args))
end

function mdl_execute(ps::ParseState)
    # preprocess "frames", "basename", "vary"
    i = 1
    while i <= length(ps.commands)
        c = ps.commands[i]
        if c.func === mdlframes || c.func === mdlbasename
            c.func(ps, c.args...)
            deleteat!(ps.commands, i)
        else
            i += 1
        end
    end

    i = 1
    while i <= length(ps.commands)
        c = ps.commands[i]
        if c.func === mdlvary
            mdlvary(ps, c.args...)
            deleteat!(ps.commands, i)
        else
            i += 1
        end
    end

    mktempdir() do tmp
        reference = ps
        @sync @parallel for current in 1:reference.nframes
            if reference.nframes > 1
                println("Processing frame ", current)
                ps = deepcopy(reference)
            end

            ps.cframe = current
            for c in ps.commands
                c.func(ps, c.args...)
            end

            ps.nframes > 1 && mdlsave(ps, joinpath(tmp, string(ps.basename, lpad(current, 4, 0), ".png")))
        end
    end
end
end

