__precompile__()
module Edgematrix

using Config
using Line

export Edges, transform!, addedge!, addcircle!, addcurve!, drawem!

mutable struct Edges
    em::Vector{Vector{Float64}}
    Edges() = new(Vector{Vector{Float64}}())
end

function addpoint!(this, data)
    while size(data, 1) < 4
        push!(data, 1.0)
    end
    push!(this.em, data[1:4])
end

function transform!(this, transmatrix)
    tmpmat = transmatrix * hcat(this.em...)
    this.em = [tmpmat[:, i] for i in 1:size(tmpmat, 2)]
end


function addedge!(this, p1, p2)
    addpoint!(this, p1)
    addpoint!(this, p2)
end

function addcircle!(this, center, radius, steps)
    segstart = center + [radius, 0, 0]
    for t in [i/steps for i in 1:steps]
        segend = center + radius * [cos(2pi * t), sin(2pi * t), 0]
        addedge!(this, segstart, segend)
        segstart = segend
    end
end

function addcurve!(this, p1, p2, p3, p4, steps, ctype)
    xcoefs = CURVES[ctype] * [p1[1]; p2[1]; p3[1]; p4[1]]
    ycoefs = CURVES[ctype] * [p1[2]; p2[2]; p3[2]; p4[2]]

    for t in [i/steps for i in 1:steps]
        # at^3 + bt^2 + ct + d
        p2 = [xcoefs[1] * t^3 + xcoefs[2] * t^2  + xcoefs[3] * t + xcoefs[4],
              ycoefs[1] * t^3 + ycoefs[2] * t^2  + ycoefs[3] * t + ycoefs[4],
              0]
        addedge!(this, p1, p2)
        p1 = p2
    end
end

function drawem!(this, display, color)
    for i in 1:2:(size(this.em, 1) - 1)
        drawline!(display,
                  round.(Int, this.em[i]),
                  round.(Int, this.em[i + 1]),
                  color)
    end
end
end

