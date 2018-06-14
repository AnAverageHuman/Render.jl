__precompile__(true)
module mdl

using JuliaParser.Diagnostics
using JuliaParser.Lexer
using JuliaParser.Lexer: @tok, TokenStream, eof, eof_token, make_token, peekchar
using JuliaParser.Tokens: ¬, √
using Graphics
using Graphics: ParseState, modifycoord!, withem!, withpm!

export mdl_parser

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
F64 = Float64

# MDL commands
mdlpush(ps::ParseState) = push!(ps.coords, ps.coords[end])
mdlpop(ps::ParseState)  = length(ps.coords) > 1 && pop!(ps.coords)

mdlmove(ps::ParseState, x::F64, y::F64, z::F64, knob = nothing) = begin
    modifycoord!(ps, mktranslate([x, y, z]))
end

mdlscale(ps::ParseState, x::F64, y::F64, z::F64, knob = nothing) = begin
    modifycoord!(ps, mkscale([x, y, z]))
end

mdlrotate(ps::ParseState, dir::Symbol, d::F64, knob = nothing) = begin
    modifycoord!(ps, mkrotate(d, dir))
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

mdlsave(ps::ParseState, fn...) = Graphics.display(ps, `convert - $(string(fn...))`)
mdldisplay(ps::ParseState) = Graphics.display(ps, `display`)


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
    command(ps, args...)
end
end

