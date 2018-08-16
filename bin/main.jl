isempty(@__DIR__) || push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using Render

function main()
    if length(ARGS) < 1
        include(joinpath(@__DIR__, "repl.jl"))
    else
        map(x -> open(Render.renderfile, x, "r"), ARGS)
    end
end

isinteractive() || @time main()

