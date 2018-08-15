function mkscale(scalevec::Vector{Float64})
    Diagonal(scalevec)
end

function mktranslate(transvec::Vector{Float64})
    mult = Matrix(1.0I, 4, 4)
    for i in 1:3
        mult[i, 4] = transvec[i]
    end
    mult
end

function mkrotate(angle::Float64, direction::Symbol)
    sa = sind(angle)
    ca = cosd(angle)
    x = [ca, -sa, sa, ca]
    indices = ROTATIONINDICES[direction]
    mult = Matrix(1.0I, 4, 4)
    for i in 1:size(indices, 1)
        mult[indices[i, 1], indices[i, 2]] = x[i]
    end
    mult
end

