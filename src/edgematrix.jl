mutable struct Edges
    em::ElasticArray{Float64}
end
Edges() = Edges(ElasticArray{Float64}(4, 0))

size(e::Edges) = size(e.em, 2)
getindex(e::Edges, i::Union{Int,UnitRange}) = e.em[:, i]


function addpoint!(this::Edges, data::Vector{Float64})
    while size(data, 1) < 4
        push!(data, 1.0)
    end
    append!(this.em, data[1:4])
end

function transform!(this::Edges, transmatrix::Matrix{Float64})
    size(this) < 1 && return
    this.em = transmatrix * this.em
    this
end
*(x::Edges, y::Matrix{Float64}) = transform!(x, y)



function addedge!(this::Edges, p1::Vector{Float64}, p2::Vector{Float64})
    addpoint!(this, p1)
    addpoint!(this, p2)
end

function addpolygon!(this::Edges, p1::Vector{Float64}, p2::Vector{Float64}, p3::Vector{Float64})
    addpoint!(this, p1)
    addpoint!(this, p2)
    addpoint!(this, p3)
end


function addbox!(this::Edges, tl::Vector{Float64}, width::Float64, height::Float64,
                 depth::Float64)
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

function addcircle!(this::Edges, center::Vector{Float64}, radius::Float64, steps::Int)
    segstart = center + [radius, 0, 0]
    for t in [i/steps for i in 1:steps]
        segend = center + radius * [cos(2pi * t), sin(2pi * t), 0]
        addedge!(this, segstart, segend)
        segstart = segend
    end
end

function addsphere!(this::Edges, center::Vector{Float64}, radius::Float64, steps::Int)
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

function addtorus!(this::Edges, center::Vector{Float64}, irad::Float64, orad::Float64,
                   steps::Int)
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

function addcurve!(this::Edges, p1::Vector{Float64}, p2::Vector{Float64},
                   p3::Vector{Float64}, p4::Vector{Float64}, steps::Int, ctype::Symbol)
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

function drawem!(this::Edges, display::IBuffer, color::Vector{Int})
    for i in 1:2:(size(this) - 1)
        drawline!(display, this[i], this[i + 1], color)
    end
end

function drawpm!(this::Edges, display::IBuffer, view::Vector{Float64},
                 cambient::Vector{Int}, lights::Vector{Dict{Symbol, Any}},
                 reflect::Dict{Symbol, Vector{Float64}})
    # preallocate arrays
    v     = normalize(view)
    n     = Vector{Float64}(3)
    l     = Vector{Float64}(3)
    sortd = Matrix{Float64}(4, 3)
    pb    = Vector{Float64}(4)
    pm    = Vector{Float64}(4)
    pt    = Vector{Float64}(4)
    color = Vector{Float64}(3)
    dleft = Vector{Float64}(4)
    drig1 = Vector{Float64}(4)
    drig2 = Vector{Float64}(4)
    tmpa  = Vector{Float64}(4)

    # normalize all lights
    for lig in lights
        normalize!(lig[:location])
    end

    for i in 1:3:(size(this) - 2)
        # calculate the normal to see if we need to draw
        n[1:3] = cross(this[i + 1] - this[i], this[i + 2] - this[i])
        vecdot(n, view) > 0 || continue

        # sort by and round y values for cleaner spheres
        sortd[:, :] = sortcols(this[i:i + 2], by = x -> x[2])
        pb[1:4], pm[1:4], pt[1:4] = [sortd[:, i] for i in 1:size(sortd, 2)]
        pb[2] = round(Int, pb[2])
        pm[2] = round(Int, pm[2])
        pt[2] = round(Int, pt[2])

        # determine shading of a polygon
        normalize!(n)
        am, di, sp = cambient .* reflect[:ambient], 0, 0

        for lig in lights
            l[1:3] = lig[:location]
            vnl = vecdot(n, l)
            di += lig[:color] .* reflect[:diffuse] * vnl
            sp += lig[:color] .* reflect[:specular] * vecdot(v, 2n * vnl - l)^SPEC_EXP
        end
        @. color[1:3] = min(255, max(0, am) + max(0, di) + max(0 + sp))

        # fill in polygons with scanline conversion
        f(x, y) = y < 0.1 ? 0 : x / y   # avoid division by 0
        dleft[1:4] = [f(pt[1] - pb[1], pt[2] - pb[2]), 1, f(pt[3] - pb[3], pt[2] - pb[2]), 0]
        drig1[1:4] = [f(pm[1] - pb[1], pm[2] - pb[2]), 1, f(pm[3] - pb[3], pm[2] - pb[2]), 0]
        drig2[1:4] = [f(pt[1] - pm[1], pt[2] - pm[2]), 1, f(pm[3] - pb[3], pm[2] - pb[2]), 0]

        tmp = pm[2] - pb[2]
        for y in 1:tmp
            drawline!(display, pb + y * dleft, pb + y * drig1, color)
        end

        tmpa[1:4] = pb + tmp * dleft
        for y in 0:pt[2] - pm[2]
            drawline!(display, tmpa + y * dleft, pm + y * drig2, color)
        end
    end
end

