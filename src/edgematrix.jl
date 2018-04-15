__precompile__()
module Edgematrix

using Config
using Line

export Edges, transform!, addedge!, addbox!, addcircle!, addsphere!, addtorus!, addcurve!,
       drawem!, drawpm!

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
    size(this.em, 1) < 1 && return
    tmpmat = transmatrix * hcat(this.em...)
    this.em = [tmpmat[:, i] for i in 1:size(tmpmat, 2)]
end


function addedge!(this, p1, p2)
    addpoint!(this, p1)
    addpoint!(this, p2)
end

function addpolygon!(this, p1, p2, p3)
    addpoint!(this, p1)
    addpoint!(this, p2)
    addpoint!(this, p3)
end


function addbox!(this, tl, width, height, depth)
    br = tl + [width, -height, -depth] # topleft, bottomright
    # front, back right, left, top, bottom
    addpolygon!(this, [tl[1], tl[2], tl[3]], [br[1], br[2], tl[3]], [br[1], tl[2], tl[3]])
    addpolygon!(this, [tl[1], tl[2], tl[3]], [tl[1], br[2], tl[3]], [br[1], br[2], tl[3]])

    addpolygon!(this, [br[1], tl[2], br[3]], [tl[1], br[2], br[3]], [tl[1], tl[2], br[3]])
    addpolygon!(this, [br[1], tl[2], br[3]], [br[1], br[2], br[3]], [tl[1], br[2], br[3]])

    addpolygon!(this, [br[1], tl[2], tl[3]], [br[1], br[2], br[3]], [br[1], tl[2], br[3]])
    addpolygon!(this, [br[1], tl[2], tl[3]], [br[1], br[2], tl[3]], [br[1], br[2], br[3]])

    addpolygon!(this, [tl[1], tl[2], br[3]], [tl[1], br[2], tl[3]], [tl[1], tl[2], tl[3]])
    addpolygon!(this, [tl[1], tl[2], br[3]], [tl[1], br[2], br[3]], [tl[1], br[2], tl[3]])

    addpolygon!(this, [tl[1], tl[2], br[3]], [br[1], tl[2], tl[3]], [br[1], tl[2], br[3]])
    addpolygon!(this, [tl[1], tl[2], br[3]], [tl[1], tl[2], tl[3]], [br[1], tl[2], tl[3]])

    addpolygon!(this, [tl[1], br[2], tl[3]], [br[1], br[2], br[3]], [br[1], br[2], tl[3]])
    addpolygon!(this, [tl[1], br[2], tl[3]], [tl[1], br[2], br[3]], [br[1], br[2], br[3]])
end

function addcircle!(this, center, radius, steps)
    segstart = center + [radius, 0, 0]
    for t in [i/steps for i in 1:steps]
        segend = center + radius * [cos(2pi * t), sin(2pi * t), 0]
        addedge!(this, segstart, segend)
        segstart = segend
    end
end

function addsphere!(this, center, radius, steps)
    points = Vector{Vector{Float64}}()

    for rott in [i/steps for i in 0:steps], cirt in [i/steps for i in 0:steps]
        push!(points, center + radius * [cos(pi * cirt),
                                         sin(pi * cirt) * cos(2pi * rott),
                                         sin(pi * cirt) * sin(2pi * rott)])
    end

    ns = steps + 1
    for latt in 0:steps - 1, long in 0:steps - 1
        i = latt * ns + long
        p = [i, i + 1, (i + 1 + ns) % length(points), (i + ns) % length(points)] + 1
        addpolygon!(this, points[p[1]], points[p[2]], points[p[3]])
        addpolygon!(this, points[p[1]], points[p[3]], points[p[4]])
    end
end

function addtorus!(this, center, irad, orad, steps)
    # irad: radius of a "slice"         orad: radius of the entire torus
    points = Vector{Vector{Float64}}()

    for rott in [i/steps for i in 0:steps], cirt in [i/steps for i in 0:steps]
        push!(points, center + [cos(2pi * rott) * (irad * cos(2pi * cirt) + orad),
                                irad * sin(2pi * cirt),
                                -sin(2pi * rott) * (irad * cos(2pi * cirt) + orad)])
    end

    for latt in 0:steps, long in 1:steps
        i = latt * steps + long
        addedge!(this, points[i], points[i] + 1)
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

function drawpm!(this, display, color)
    for i in 1:3:(size(this.em, 1) - 2)
        drawline!(display, round.(Int, this.em[i]),     round.(Int, this.em[i + 1]), color)
        drawline!(display, round.(Int, this.em[i + 2]), round.(Int, this.em[i + 1]), color)
        drawline!(display, round.(Int, this.em[i]),     round.(Int, this.em[i + 2]), color)
    end
end
end

