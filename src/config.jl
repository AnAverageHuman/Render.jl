__precompile__()
module Config

export MAGICNUMBER, DIMC, DIMR, DIMD, MAXCOLOR
export ROTATIONINDICES
export CIRCSTEPS, SPHSTEPS, TORUSTEPS, BEZSTEPS, HERMSTEPS, CURVES
export CAMBIENT, LIGHTS, VIEWVEC, REFLECTION, SPEC_EXP

const MAGICNUMBER = "P3"
const DIMC = 500
const DIMR = 500
const DIMD = 1
const MAXCOLOR = 255

const ROTATIONINDICES = Dict("x" => [2 2; 2 3; 3 2; 3 3],
                             "y" => [1 1; 3 1; 1 3; 3 3],
                             "z" => [1 1; 1 2; 2 1; 2 2])

const CIRCSTEPS = 360
const SPHSTEPS  = 100
const TORUSTEPS = 100
const BEZSTEPS  = 100
const HERMSTEPS = 100

const CURVES = Dict("bezier"  => [-1  3 -3  1;  3 -6  3  0; -3  3  0  0;  1  0  0  0],
                    "hermite" => [ 2 -2  1  1; -3  3 -2 -1;  0  0  1  0;  1  0  0  0])


const CAMBIENT = [ 50,  50,  50]

const LIGHTS = [Dict("location" => [0.50, 0.75, 1.00],
                     "color"    => [  0, 255, 255])]

const VIEWVEC = [ 0.00,  0.00,  1.00]

const REFLECTION = Dict("ambient"  => [0.10, 0.10, 0.10],
                        "diffuse"  => [0.50, 0.50, 0.50],
                        "specular" => [0.50, 0.50, 0.50])
const SPEC_EXP = 16
end

