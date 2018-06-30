isempty(@__DIR__) || push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
using Render: parsefile

function main()
    # assume first argument is the filename
    length(ARGS) < 1 && error("At least one script must be provided.")
    map(x -> open(parsefile, x, "r"), ARGS)
end

isinteractive() || @time main()

