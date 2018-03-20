__precompile__()
module Config

export MAGICNUMBER, DIMC, DIMR, DIMD, MAXCOLOR, ROTATIONINDICES

const MAGICNUMBER = "P3"
const DIMC = 500
const DIMR = 500
const DIMD = 1
const MAXCOLOR = 255

const ROTATIONINDICES = Dict("x" => [2 2; 2 3; 3 2; 3 3],
                             "y" => [1 1; 3 1; 1 3; 3 3],
                             "z" => [1 1; 1 2; 2 1; 2 2])
end

