__precompile__()
module Edgematrix

using Config
using Line

import Base.*     # required to extend *

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

*(x::Edges, y) = transform!(x, y)



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

    ns = steps + 1
    for latt in 0:steps - 1, long in 0:steps - 1
        i = latt * ns + long
        p = [i, i + 1, (i + 1 + ns) % ns^2, (i + ns) % ns^2] + 1

        addpolygon!(this, points[p[1]], points[p[4]], points[p[3]])
        addpolygon!(this, points[p[1]], points[p[3]], points[p[2]])
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
    for i in 1:2:(size(this, 1) - 1)
        drawline!(display, this[i], this[i + 1], color)
    end
end

function drawpm!(this, display, view, cambient, lights, reflect)
    for i in 1:3:(size(this, 1) - 2)
        # calculate the normal to see if we need to draw
        normal = cross(this[i + 1] - this[i], this[i + 2] - this[i])
        vecdot(normal, view) > 0 || continue

        # sort by and round y values for cleaner spheres
        pb, pm, pt = sort(this[i:i + 2], by = x -> x[2])
        for point in [pb, pm, pt]
            point[2] = round(Int, point[2])
        end

        # determine shading of a polygon
        n, v, l = normalize.([normal, view, lights[1]["location"]]) # currently only 1 light

        am = cambient .* reflect["ambient"]
        di = lights[1]["color"] .* reflect["diffuse"] * vecdot(n, l)
        sp = lights[1]["color"] .* reflect["specular"] * vecdot(v, 2n * vecdot(n, l) - l)^SPEC_EXP
        color = @parallel (+) for i in [am, di, sp]
            max.(i, 0)
        end

        color = min.(color, 255)

        # fill in polygons with scanline conversion
        f(x, y) = y < 0.1 ? 0 : x / y   # avoid division by 0
        dleft = [f(pt[1] - pb[1], pt[2] - pb[2]), 1, f(pt[3] - pb[3], pt[2] - pb[2]), 0]
        drig1 = [f(pm[1] - pb[1], pm[2] - pb[2]), 1, f(pm[3] - pb[3], pm[2] - pb[2]), 0]
        drig2 = [f(pt[1] - pm[1], pt[2] - pm[2]), 1, f(pm[3] - pb[3], pm[2] - pb[2]), 0]

        left = right = pb
        tmp = pm[2] - pb[2]
        for y in 1:tmp
            drawline!(display, left + y * dleft, right + y * drig1, color)
        end

        left = left + tmp * dleft
        right = pm

        for y in 0:pt[2] - pm[2]
            drawline!(display, left + y * dleft, right + y * drig2, color)
        end
    end
end
end

