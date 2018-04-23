include("config.jl")
include("display.jl")
include("line.jl")
include("edgematrix.jl")
include("matrixutil.jl")

using Config
using Display
using Edgematrix
using Matrixutil

THEDISPLAY = zeros(Int, 3, DIMD, DIMC, DIMR)
dumpthedisplay(f) = dump_ppm(THEDISPLAY, f)

function modifystack(stack, trans)
    push!(stack, pop!(stack) * trans)
end

function parsefile(f::IOStream)
    global THEDISPLAY = zeros(THEDISPLAY)
    items = readdlm(f, String)
    items = vec(permutedims(items, (2, 1)))
    filter!(x -> x != "", items)

    edges = Edges()
    polygons = Edges()
    cs = [eye(4)]
    transmat = eye(4)

    while ! isempty(items)
        command = shift!(items)
        if command == "line"
            tmp = [parse(Float64, x) for x in splice!(items, 1:6)]
            addedge!(edges, tmp[1:3], tmp[4:6])
            drawem!(edges * cs[end], THEDISPLAY, [255, 255, 255])
            edges = Edges()
        elseif command == "circle"
            tmp = [parse(Float64, x) for x in splice!(items, 1:4)]
            addcircle!(edges, tmp[1:3], tmp[4], CIRCSTEPS)
            drawem!(edges * cs[end], THEDISPLAY, [255, 255, 255])
            edges = Edges()
        elseif command == "sphere"
            tmp = [parse(Float64, x) for x in splice!(items, 1:4)]
            addsphere!(polygons, tmp[1:3], tmp[4], SPHSTEPS)
            drawpm!(polygons * cs[end], THEDISPLAY, [255, 255, 255])
            polygons = Edges()
        elseif command == "torus"
            tmp = [parse(Float64, x) for x in splice!(items, 1:5)]
            addtorus!(polygons, tmp[1:3], tmp[4], tmp[5], TORUSTEPS)
            drawpm!(polygons * cs[end], THEDISPLAY, [255, 255, 255])
            polygons = Edges()
        elseif command == "box"
            tmp = [parse(Float64, x) for x in splice!(items, 1:6)]
            addbox!(polygons, tmp[1:3], tmp[4], tmp[5], tmp[6])
            drawpm!(polygons * cs[end], THEDISPLAY, [255, 255, 255])
            polygons = Edges()
        elseif command == "hermite"
            tmp = [parse(Float64, x) for x in splice!(items, 1:8)]
            addcurve!(edges, tmp[1:2], tmp[3:4], tmp[5:6], tmp[7:8], HERMSTEPS, "hermite")
            drawem!(edges * cs[end], THEDISPLAY, [255, 255, 255])
            edges = Edges()
        elseif command == "bezier"
            tmp = [parse(Float64, x) for x in splice!(items, 1:8)]
            addcurve!(edges, tmp[1:2], tmp[3:4], tmp[5:6], tmp[7:8], BEZSTEPS, "bezier")
            drawem!(edges * cs[end], THEDISPLAY, [255, 255, 255])
            edges = Edges()
        elseif command == "push"
            push!(cs, cs[end])
        elseif command == "pop"
            length(cs) > 1 && pop!(cs)
        elseif command == "scale"
            tmp = [parse(Float64, x) for x in splice!(items, 1:3)]
            modifystack(cs, mkscale(tmp[1:3]))
        elseif command == "move"
            tmp = [parse(Float64, x) for x in splice!(items, 1:3)]
            modifystack(cs, mktranslate(tmp[1:3]))
        elseif command == "rotate"
            dir = shift!(items)
            modifystack(cs, mkrotate(parse(Float64, shift!(items)), dir))
        elseif command == "quit"
            break
        elseif command == "display"
            open(dumpthedisplay, `display`, "w")
        elseif command == "save"
            open(dumpthedisplay, `convert - $(shift!(items))`, "w")
        else
            warn("could not interpret ", command)
        end
    end
end

function main()
    # assume first argument is the filename
    length(ARGS) < 1 && error("At least one script must be provided.")
    map(x -> open(parsefile, x, "r"), ARGS)
end

main()

