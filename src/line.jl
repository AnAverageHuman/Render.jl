__precompile__()
module Line

using Display: plot!

export drawline!

function drawline!(data, p1, p2, color)
    global dx, dy, x, y
    x = p1[1]
    y = p1[2]
    dx = p2[1] - p1[1]
    dy = p2[2] - p1[2]

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
    global dx, dy, x, y
    yi = 1
    if dy < 0
        yi = -1
        dy = -dy
    end

    d = 2dy - dx
    for i in x:mx
        plot!(data, [1, y, i], color)
        d += 2dy

        if d > 0
            y += yi
            d -= 2dx
        end
    end
end

function drawlinehigh!(data, my, color)
    global dx, dy, x, y
    xi = 1
    if dx < 0
        xi = -1
        dx = -dx
    end

    d = 2dx -dy
    for i in y:my
        plot!(data, [1, i, x], color)
        d += 2dx

        if d > 0
            x += xi
            d -= 2dy
        end
    end
end
end

