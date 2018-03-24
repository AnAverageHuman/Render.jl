__precompile__()
module Edgematrix

using Line

export Edges, transform!, addedge!, drawem!

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

function drawem!(this, display, color)
    for i in 1:2:(size(this.em, 1) - 1)
        drawline!(display,
                  round.(Int, this.em[i]),
                  round.(Int, this.em[i + 1]),
                  color)
    end
end
end

