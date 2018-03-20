__precompile__()
module Matrixutil

export mkscale, mktranslate

function mkscale(scalevec)
    mult = eye(4)
    for i in 1:size(scalevec, 1)
        mult[i, i] = scalevec[i]
    end
    mult
end

function mktranslate(transvec)
    mult = eye(4)
    for i in 1:3
        mult[i, 4] = transvec[i]
    end
    mult
end
end

