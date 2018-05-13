struct IBuffer
    disp::Array{UInt, 3}
    zbuf::Matrix{Float64}
    IBuffer(r::Int, c::Int) = new(zeros(3, c, r), fill(-Inf, c, r))
end
IBuffer() = IBuffer(DIMR, DIMC)

function dump_ppm(d::IBuffer, file=STDOUT)
    write(file, "$MAGICNUMBER $(size(d.disp, 3)) $(size(d.disp, 2))  $MAXCOLOR\n")
    writedlm(file, d.disp)
end

function plot!(d::IBuffer, point, color)
    # origin should be in lower left instead of upper left
    point = point[1], point[3], size(d.disp, 2) - point[2] - 1
    point = round.(Int, point)
    color = round.(Int, color)

    1 < point[2] < size(d.disp, 2) || return
    1 < point[3] < size(d.disp, 3) || return
    point[1] > d.zbuf[point[2], point[3]] || return

    d.disp[:, point[2], point[3]] = color
    d.zbuf[point[2], point[3]] = point[1]
end

