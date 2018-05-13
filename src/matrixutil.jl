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

function mkrotate(angle, direction)
    x = [cosd(angle), -sind(angle), sind(angle), cosd(angle)]
    indices = ROTATIONINDICES[direction]
    mult = eye(4)
    for i in 1:size(indices, 1)
        mult[indices[i, 1], indices[i, 2]] = x[i]
    end
    mult
end

