struct IBuffer
    disp::Array{UInt8, 3}
    zbuf::Matrix{Float64}
    IBuffer(r::Int, c::Int) = new(zeros(3, c, r), fill(-Inf, c, r))
end
IBuffer() = IBuffer(DIMR, DIMC)

function dump_ppm_p3(d::IBuffer, io::IO)
    _, w, h = size(d.disp)
    write(io, "P3 $w $h $MAXCOLOR\n")
    writedlm(io, Int16.(d.disp))
end

function dump_ppm_p6(d::IBuffer, io::IO)
    _, w, h = size(d.disp)
    write(io, collect(UInt8, "P6 $w $h $MAXCOLOR\n"))
    write(io, d.disp)
end

function plot!(d::IBuffer, point::Vector{Float64}, color::Vector{Float64})
    # origin should be in lower left instead of upper left
    point = point[1], point[3], size(d.disp, 2) - point[2] - 1

    1 < point[2] < size(d.disp, 2) || return
    1 < point[3] < size(d.disp, 3) || return
    rpoint2 = round(Int, point[2])
    rpoint3 = round(Int, point[3])
    point[1] > d.zbuf[rpoint2, rpoint3] || return

    d.disp[:, rpoint2, rpoint3] = round.(UInt8, color)
    d.zbuf[rpoint2, rpoint3] = point[1]
end

