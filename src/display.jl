__precompile__()
module Display

using Config

export dump_ppm, plot!

function dump_ppm(data, file=STDOUT)
    write(file, "$MAGICNUMBER $(size(data, 4)) $(size(data, 3))  $MAXCOLOR\n")
    writedlm(file, data)
end

function plot!(data, point, color)
    # origin should be in lower left instead of upper left
    point = point[1], point[3], size(data, 3) - point[2] - 1
    1 < point[2] < size(data, 4) || return
    1 < point[3] < size(data, 3) || return

    data[:, point[1], point[2], point[3]] = color
end
end

