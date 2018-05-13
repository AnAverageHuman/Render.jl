function drawline!(data, p1, p2, color)
    global dx, dy, dz, x, y, z
    all(isfinite.(p1)) && all(isfinite.(p2)) || return    # refuse to draw NaN and Inf

    x = p1[1]
    y = p1[2]
    z = p1[3]
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]
    dz = p2[3] - p1[3]

    if abs(dy) < abs(dx)
        if p1[1] > p2[1]
            drawline!(data, p2, p1, color)
        else
            drawlinelow!(data, p2[1], color)
        end
    else
        if p1[2] > p2[2]
            drawline!(data, p2, p1, color)
        else
            drawlinehigh!(data, p2[2], color)
        end
    end
end

function drawlinelow!(data, mx, color)
    global dx, dy, dz, x, y, z
    yi = 1
    if dy < 0
        yi = -1
        dy = -dy
    end

    d = 2dy - dx
    dist = abs(mx - x)
    dz = dist > 0 ? dz / dist : 0
    for i in x:mx
        plot!(data, [z, y, i], color)
        d += 2dy
        z += dz

        if d > 0
            y += yi
            d -= 2dx
        end
    end
end

function drawlinehigh!(data, my, color)
    global dx, dy, dz, x, y, z
    xi = 1
    if dx < 0
        xi = -1
        dx = -dx
    end

    d = 2dx -dy
    dist = abs(my - y)
    dz = dist > 0 ? dz / dist : 0

    for i in y:my
        plot!(data, [z, i, x], color)
        d += 2dx
        z += dz

        if d > 0
            x += xi
            d -= 2dy
        end
    end
end

