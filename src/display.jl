__precompile__()
module Display

using Config

export dump_ppm, plot!

function dump_ppm(data, file=STDOUT)
    write(file, "$MAGICNUMBER $(size(data, 4)) $(size(data, 3))  $MAXCOLOR\n")
    writedlm(file, data)
end

function plot!(data, point, color)
    data[:, point[1], point[2], point[3]] = color
end
end

