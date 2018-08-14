__precompile__(true)
module mdl

using Distributed: @distributed
using Tokenize: Lexers.Lexer, untokenize
using Tokenize.Tokens: kind, startpos, ENDMARKER, FLOAT, INTEGER
using Render
using Render: ParseState, modifycoord!, parseNumber, withem!, withpm!

export mdl_execute, mdl_parser

COMMENT = "//"


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
    ps.symtab[knob] = get(ps.symtab, knob, Render.Knob(sf, ef, sv, ev, ps.nframes))
    ps.symtab[knob].frdata[sf:ef - 1] = [sv + (ev - sv) / (ef - sf) * i for i in 1:(ef - sf)]
end

mdlsave(ps::ParseState, fn...) = Render.display(ps, `convert - $(string(fn...))`)

mdldisplay(ps::ParseState) = begin
    if ps.nframes > 1
        run(`animate -delay $(Render.ANIM_DELAY) "$tmp/$(ps.basename)*"`)
    else
        Render.display(ps, `display`)
    end
end


function mdl_parser(ts::Lexer, ps::ParseState)
    next = iterate(ts)

    while next !== nothing
        (tok, state) = next

        kind(tok) === ENDMARKER && break

        if untokenize(tok) === "\n"
            next = iterate(ts, state)
            continue
        end

        if untokenize(tok) == COMMENT
            while untokenize(tok) !== "\n"
                next = iterate(ts, state)
                if next !== nothing
                    (tok, state) = next
                else
                    continue
                end
            end
            continue
        end

        command = untokenize(tok)
        try
            command = getfield(mdl, Symbol(:mdl, command))
        catch UndefVarError
            error("at $(startpos(tok)): expected MDL command, got [$(command)]")
        end
        next = iterate(ts, state)

        args = Vector()
        while next !== nothing
            (tok, state) = next
            tokkind = kind(tok)
            t = untokenize(tok)
            t === "\n" && break

            if t === "-"    # we expect a number here
                next = iterate(ts, state)
                (tok, state) = next
                val = parseNumber(tok)
                push!(args, -val)
            elseif tokkind === INTEGER || tokkind === FLOAT
                push!(args, parseNumber(tok))
            elseif t !== " "
                push!(args, Symbol(t))
            end

            next = iterate(ts, state)
        end

        push!(ps.commands, Render.GCommand(command, args))
    end
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
        @sync @distributed for current in 1:reference.nframes
            if reference.nframes > 1
                println("Processing frame ", current)
                ps = deepcopy(reference)
            end

            ps.cframe = current
            for c in ps.commands
                c.func(ps, c.args...)
            end

            ps.nframes > 1 && mdlsave(ps, joinpath(tmp, string(ps.basename,
                                                               lpad(string(current), 4, string(0)),
                                                               ".png")))
        end
    end
end
end

