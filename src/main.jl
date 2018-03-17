include("config.jl")
include("display.jl")

using Config
using Display

function main()
    const THEDISPLAY = zeros(Int, 3, DIMD, DIMC, DIMR)
    dump_ppm(THEDISPLAY)
end

main()

