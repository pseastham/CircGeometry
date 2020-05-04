using Plots

pyplot(aspect_ratio=:equal)

"""
    visualize_circles(file_input)

Plots circles found in *.circ type file in ../ folder and exports to png
"""
function visualize_circles(file_input::String)
    # read in circ file
    circfile = string(file_input)
    f         = open(circfile,"r")
    lines     = readlines(f)
    num_lines = length(lines)
    close(f)

    # obtain pre-processing parameters (# bodies, radii, x/y centers)
    nbodies = parse(Int,lines[2])
    radiusArr = zeros(nbodies)
    xArr = zeros(nbodies)
    yArr = zeros(nbodies)

    tind = 1
    for ti = 4:3:num_lines-1
        radiusArr[tind] = parse(Float64,lines[ti])
        xArr[tind] = parse(Float64,lines[ti+1])
        yArr[tind] = parse(Float64,lines[ti+2])
        tind += 1
    end

    # initialize figure
    p = plot(color=:black)

    # loop over circles and plot
    for ti=1:nbodies
        plot_circle!(p,radiusArr[ti],xArr[ti],yArr[ti])
    end

    # export figure
    display(p)
end

"""
    plot_circle(p,radius,x,y)

plots circle to plot object p. Circle has center (x,y)
"""
function plot_circle!(p,radius,x,y)
    nθ = 40
    θarr = 0:2*pi/(nθ-1):2*pi

    plot!(p,x .+ radius*cos.(θarr),y .+ radius*sin.(θarr),label="",color=:black)

    nothing
end
