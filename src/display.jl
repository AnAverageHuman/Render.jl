__precompile__()
module Display

using Config

export dump_ppm

function dump_ppm(data, file=STDOUT)
    write(file, "$MAGICNUMBER $(size(data, 4)) $(size(data, 3))  $MAXCOLOR\n")
    writedlm(file, data)
end
end

