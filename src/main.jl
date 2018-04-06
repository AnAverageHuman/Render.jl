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
const edges = Edges()
transmat = eye(4)

dumpthedisplay(f) = dump_ppm(THEDISPLAY, f)

function parsefile(f::IOStream)
    global transmat, THEDISPLAY
    items = readdlm(f, String)
    items = vec(permutedims(items, (2, 1)))
    filter!(x -> x != "", items)
    tmp = zeros(10)

    while ! isempty(items)
        command = shift!(items)
        if command == "line"
            tmp = [parse(Float64, x) for x in splice!(items, 1:6)]
            addedge!(edges, tmp[1:3], tmp[4:6])
        elseif command == "circle"
            tmp = [parse(Float64, x) for x in splice!(items, 1:4)]
            addcircle!(edges, tmp[1:3], tmp[4], CIRCSTEPS)
        elseif command == "hermite"
            tmp = [parse(Float64, x) for x in splice!(items, 1:8)]
            addcurve!(edges, tmp[1:2], tmp[3:4], tmp[5:6], tmp[7:8], HERMSTEPS, "hermite")
        elseif command == "bezier"
            tmp = [parse(Float64, x) for x in splice!(items, 1:8)]
            addcurve!(edges, tmp[1:2], tmp[3:4], tmp[5:6], tmp[7:8], BEZSTEPS, "bezier")
        elseif command == "ident"
            transmat = eye(4)
        elseif command == "scale"
            tmp = [parse(Float64, x) for x in splice!(items, 1:3)]
            transmat = mkscale(tmp[1:3]) * transmat
        elseif command == "move"
            tmp = [parse(Float64, x) for x in splice!(items, 1:3)]
            transmat = mktranslate(tmp[1:3]) * transmat
        elseif command == "rotate"
            dir = shift!(items)
            transmat = mkrotate(parse(Float64, shift!(items)), dir) * transmat
        elseif command == "apply"
            transform!(edges, transmat)
        elseif command == "quit"
            break
        elseif command == "display"
            THEDISPLAY = zeros(THEDISPLAY)
            drawem!(edges, THEDISPLAY, [255, 255, 255])
            open(dumpthedisplay, `display`, "w")
        elseif command == "save"
            drawem!(edges, THEDISPLAY, [255, 255, 255])
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

