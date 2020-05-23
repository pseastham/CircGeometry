import CSV: Rows
import Statistics: mean
using Plots

"""
    write_circ(file_name,ps)

Takes PorousStructure `ps` and writes `circ` file 
(text file) with name `file_name`
"""
function write_circ(file_name::String,ps::PorousStructure)
    filepath = string(file_name)
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

"""
    csv_to_polygon(file_name)

Reads in csv file containing (x,y) coordinates of points. Returns
arrays of `Point` type.
"""
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

    rescale_polygon!(xArr,yArr)
    center_polygon!(xArr,yArr)

    pList = [Point(xArr[ti],yArr[ti]) for ti=1:n_lines]

    return pList
end

"""
    center_polygon!(xArr,yArr)

Takes in list of points as two arrays, and centers them. Especially
useful for taking in points obtains from, for example, Inkscape which
often is translated to random points in the plane
"""
function center_polygon!(xArr::Vector{T},yArr::Vector{T}) where T<:Real
    xCenter = 0.5*(maximum(xArr) + minimum(xArr))
    yCenter = 0.5*(maximum(yArr) + minimum(yArr))
    for ti=1:length(xArr)
        xArr[ti] -= xCenter
        yArr[ti] -= yCenter
    end
    nothing
end

"""
    rescale_polygon!(xArr,yArr)

Takes in list of points as two arrays, and rescales them so that the 
minimum axis (either horizontal or vertical) has length 1. Notably,
this function keeps the same aspect ratio.
"""
function rescale_polygon!(xArr::Vector{T},yArr::Vector{T}) where T<:Real
    xlength = maximum(xArr) - minimum(xArr)
    ylength = maximum(yArr) - minimum(yArr)
    len = minimum([xlength,ylength])
    for ti=1:length(xArr)
        xArr[ti] /= len
        yArr[ti] /= len
    end
    nothing
end

function translate!(ps::PorousStructure,xval::T,yval::T) where T<:Real
    for ti=1:length(ps.olist)
        ps.olist[ti].center.x += xval
        ps.olist[ti].center.y += yval
    end
    nothing
end

function translate!(outline::OutlineCircle,xval::T,yval::T) where T<:Real
    outline.center.x += xval;
    outline.center.y += yval;
    nothing
end
function translate!(outline::OutlineRectangle,xval::T,yval::T) where T<:Real
    outline.p1.x += xval;
    outline.p1.y += yval;
    outline.p2.x += xval;
    outline.p2.y += yval;
    nothing
end
function translate!(outline::OutlinePolygon,xval::T,yval::T) where T<:Real
    for ti=1:length(outline.pList)
        outline.pList[ti].x += xval;
        outline.pList[ti].y += yval;
    end
    nothing
end

"""
    save_image(output_name,ps;fill=:blue)

Saves image of filled in objects to file 
with name output_name (recommended file type: svg)
with option to choose fill color
"""
function save_image(output_name::String,ps::PorousStructure;fill=:blue)
    # initialize figure
    p = plot(color=:black,aspect_ratio=1)

    # plot circles
    for ti=1:ps.param.n_objects
        plot_circle!(p,ps.radiiArr[ti],ps.xArr[ti],ps.yArr[ti])
    end

    savefig(p,output_name)
end
"""
    save_image(output_name,ps,outline)

Saves image of outline and filled in objects to file 
with name output_name (recommended file type: svg)
with option to choose fill color
"""
function save_image(output_name::String,ps::PorousStructure,outline::O;fill=:blue) where O<:AbstractOutlineObject
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
"""
    save_image(output_name,circ_file,outline)

Saves image of outline and filled in objects from
circ file to file with name output_name (recommended file 
type: svg) with option to choose fill color
"""
function save_image(output_name::String,circ_file::String,outline::O;fill=:blue) where O<:AbstractOutlineObject
    # load in circ object
    radiusArr, xArr, yArr = read_in_circ(circ_file)

    # initialize figure
    p = plot(color=:black,aspect_ratio=1)

    # plot circles
    n_objects = length(radiusArr)
    for ti=1:n_objects
        plot_circle!(p,radiusArr[ti],xArr[ti],yArr[ti];fill=fill)
    end
    plot_outline!(p,outline)

    savefig(p,output_name)
end

function save_image(output_name::String,psArr::Vector{PorousStructure},cArr)
    # initialize figure
    p = plot(color=:black,aspect_ratio=1)

    # plot circles
    for tk=1:length(psArr)
        for ti=psArr[tk].param.n_objects
        plot_circle!(p,psArr[tk].radiiArr[ti],psArr[tk].xArr[ti],psArr[tk].yArr[ti];fill = cArr[tk])
    end

    savefig(p,output_name)
end

"""
    read_in_circ(file_input)

Takes circ file with name `file_input` and returns arrays 
of radii, x, and y coordinates.
"""
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
    plot_circle!(p,radius,x,y;color=:blue)

Adds a circle to plot object `p`. Circle has center (x,y). Has option
to select fill-in color
"""
function plot_circle!(p::Plots.Plot{Plots.GRBackend},radius::T,x::T,y::T;fill=:blue) where T<:Real
    nθ = 40
    θarr = 0:2*pi/(nθ-1):2*pi

    plot!(p,
        x .+ radius*cos.(θarr),y .+ radius*sin.(θarr),
        seriestype=[:shape,],lw=0.5,c=fill,
        linecolor=:black,legend=false,
        fillalpha=0.2)

    nothing
end

"""
    plot_outline!(p,outline)

Adds a outline to plot object `p`. Contains different methods
for different outline types (circle, rectangle, polygon).
"""
function plot_outline!(p::Plots.Plot{Plots.GRBackend},outline::OutlineCircle{T}) where T<:Real
    nθ = 100
    θarr = 0:2*pi/(nθ-1):2*pi

    plot!(p,
        outline.center.x .+ outline.radius*cos.(θarr),
        outline.center.y .+ outline.radius*sin.(θarr),
        label="",color=:black,linestyle=:dash)

    nothing
end
function plot_outline!(p::Plots.Plot{Plots.GRBackend},outline::OutlineRectangle{T}) where T<:Real
    nn = 3

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