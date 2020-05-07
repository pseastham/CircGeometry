import CSV: Rows
import Statistics: mean
using Plots

function write_circ(file_name::String,ps::PorousStructure)
    filepath = string(file_name,".circ")
    open(filepath, "w") do io
        println(io, "# nbods")
        println(io, ps.param.n_objects)
        println(io, "# data below: radius, xc, yc for each body.")
        for ti=1:ps.param.n_objects
            println(io, ps.olist[ti].radius)
            println(io, ps.olist[ti].center.x)
            println(io, ps.olist[ti].center.y)
        end
    end
end

function csv_to_polygon(file_name::String)
    n_lines = 0
    for row in Rows(file_name;datarow=1)
        n_lines += 1
    end

    xArr = zeros(n_lines)
    yArr = zeros(n_lines)

    ind = 1
    for row in Rows(file_name;datarow=1)
        xArr[ind] = parse(Float64,row[1])
        yArr[ind] = parse(Float64,row[2])
        ind += 1
    end

    rescale!(xArr,yArr)
    center!(xArr,yArr)

    pList = [Point(xArr[ti],yArr[ti]) for ti=1:n_lines]

    return pList
end

function center!(xArr::Vector{T},yArr::Vector{T}) where T<:Real
    xCenter = 0.5*(maximum(xArr) + minimum(xArr))
    yCenter = 0.5*(maximum(yArr) + minimum(yArr))
    for ti=1:length(xArr)
        xArr[ti] -= xCenter
        yArr[ti] -= yCenter
    end
    nothing
end

function rescale!(xArr::Vector{T},yArr::Vector{T}) where T<:Real
    xlength = maximum(xArr) - minimum(xArr)
    ylength = maximum(yArr) - minimum(yArr)
    len = minimum([xlength,ylength])
    for ti=1:length(xArr)
        xArr[ti] /= len
        yArr[ti] /= len
    end
    nothing
end

function save_image(output_name::String,ps::PorousStructure,outline::O) where O<:AbstractOutlineObject
    # initialize figure
    p = plot(color=:black,aspect_ratio=1)

    # plot circles
    for ti=1:ps.param.n_objects
        plot_circle!(p,ps.radiiArr[ti],ps.xArr[ti],ps.yArr[ti])
    end

    # plot outline
    plot_outline!(p,outline)

    savefig(p,output_name)
end

function save_image(output_name::String,circ_file::String,outline::O) where O<:AbstractOutlineObject
    # load in circ object
    radiusArr, xArr, yArr = read_in_circ(file_input)

    # initialize figure
    p = plot(color=:black,aspect_ratio=1)

    # plot circles
    for ti=1:ps.param.n_objects
        plot_circle!(p,radiiArr[ti],xArr[ti],yArr[ti])
    end
    plot_outline!(p,outline)

    savefig(p,output_name)
end

"""
    visualize_circles(file_input)

Plots circles found in *.circ type file in ../ folder and exports to png
"""
function visualize_circles(file_input::String)
    radiusArr, xArr, yArr = read_in_circ(file_input)

    # initialize figure
    p = plot(color=:black)

    # loop over circles and plot
    for ti=1:nbodies
        plot_circle!(p,radiusArr[ti],xArr[ti],yArr[ti])
    end

    # export figure
    display(p)
end

function read_in_circ(file_input::String)
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
    return radiusArr, xArr, yArr
end
"""
    plot_circle(p,radius,x,y)

plots circle to plot object p. Circle has center (x,y)
"""
function plot_circle!(p::Plots.Plot{Plots.GRBackend},radius::T,x::T,y::T) where T<:Real
    nθ = 40
    θarr = 0:2*pi/(nθ-1):2*pi

    plot!(p,
        x .+ radius*cos.(θarr),y .+ radius*sin.(θarr),
        seriestype=[:shape,],lw=0.5,c=:blue,
        linecolor=:black,legend=false,
        fillalpha=0.2)

    nothing
end

function plot_outline!(p::Plots.Plot{Plots.GRBackend},outline::OutlineCircle{T}) where T<:Real
    nθ = 40
    θarr = 0:2*pi/(nθ-1):2*pi

    plot!(p,
        outline.center.x .+ outline.radius*cos.(θarr),
        outline.center.y .+ outline.radius*sin.(θarr),
        label="",color=:black,linestyle=:dash)

    nothing
end
function plot_outline!(p::Plots.Plot{Plots.GRBackend},outline::OutlineRectangle{T}) where T<:Real
    nn = 40

    # plot top 
    x = range(outline.p1.x,outline.p2.x,length=nn)
    y = outline.p2.y*ones(nn)
    plot!(p,x,y,label="",color=:black,linestyle=:dash)
    # plot bottom
    y = outline.p1.y*ones(nn)
    plot!(p,x,y,label="",color=:black,linestyle=:dash)
    # plot left
    x = outline.p1.x*ones(nn)
    y = range(outline.p1.y,outline.p2.y,length=nn)
    plot!(p,x,y,label="",color=:black,linestyle=:dash)
    # plot right
    x = outline.p2.x*ones(nn)
    plot!(p,x,y,label="",color=:black,linestyle=:dash)

    nothing
end
function plot_outline!(p::Plots.Plot{Plots.GRBackend},outline::OutlinePolygon{T}) where T<:Real
    x = zeros(2)
    y = zeros(2)

    # plot first nn lines
    nn = length(outline.pList)
    for ti=1:(nn-1)
        x[1] = outline.pList[ti].x; x[2] = outline.pList[ti+1].x
        y[1] = outline.pList[ti].y; y[2] = outline.pList[ti+1].y
        plot!(p,x,y,label="",color=:black,linestyle=:dash)
    end
    # plot last one 
    x[1] = outline.pList[nn].x; x[2] = outline.pList[1].x
    y[1] = outline.pList[nn].y; y[2] = outline.pList[1].y
    plot!(p,x,y,label="",color=:black,linestyle=:dash)

    nothing
end