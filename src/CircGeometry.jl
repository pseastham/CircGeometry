module CircGeometry

import Random: MersenneTwister

abstract type AbstractFillingObject end
abstract type AbstractOutlineObject end

export MaterialParameters,
       OutlineCircle,
       OutlineRectangle,
       OutlinePolygon,
       generate_porous_structure,
       write_circ,
       csv_to_polygon

mutable struct Point{T}
    x::T
    y::T
end

include("shuffling_functions.jl")
include("polygon_functions.jl")

struct OutlineCircle{T} <: AbstractOutlineObject
    radius::T
    center::Point{T}
    buffer_percent::T
end

# p1 is lower left, p2 is upper right
struct OutlineRectangle{T} <: AbstractOutlineObject
    p1::Point{T}
    p2::Point{T}
    buffer_percent::T
end

# what assumptions need to be made about points in pList?
struct OutlinePolygon{T} <: AbstractOutlineObject
    pList::Vector{Point{T}}
    p1_bound::Point{T}
    p2_bound::Point{T}

    function OutlinePolygon(pList::Vector{Point{T}}) where T<:Real
        n_objects = length(pList)
        maxX = -10_000.0
        minX = 10_000.0
        maxY = -10_000.0
        minY = 10_000.0
        for ti=1:n_objects
            if pList[ti].x > maxX
                maxX = pList[ti].x
            elseif pList[ti].x < minX
                minX = pList[ti].x
            end
            if pList[ti].y > maxY
                maxY = pList[ti].y
            elseif pList[ti].y < minY
                minY = pList[ti].y
            end
        end
        p1_bound = Point(minX,minY)
        p2_bound = Point(maxX,maxY)

        return new{T}(pList,p1_bound,p2_bound)
    end
end

struct FillingCircle{T} <: AbstractFillingObject
    radius::T
    center::Point{T}
    buffer_percent::T
end

struct MaterialParameters{T}
    expected_volume_fraction::T
    n_objects::Int
end

struct PorousStructure{T}
    param::MaterialParameters{T}
    olist::Vector{FillingCircle{T}}
    xArr::Vector{T}
    yArr::Vector{T}
    radiiArr::Vector{T}

    function PorousStructure(param::MaterialParameters{T},radiiArr::Vector{T},between_buffer::T) where T<:Real
        olist = [FillingCircle(radiiArr[ti],Point(zero(T),zero(T)),between_buffer) for ti=1:param.n_objects]
        xArr = zeros(T,param.n_objects)
        yArr = zeros(T,param.n_objects)
        new{T}(param, olist, xArr, yArr,radiiArr)
    end
    function PorousStructure(param::MaterialParameters{T},radiiArr::Vector{T},between_buffer::Vector{T}) where T<:Real
        olist = [FillingCircle(radiiArr[ti],Point(zero(T),zero(T)),between_buffer[ti]) for ti=1:param.n_objects]
        xArr = zeros(T,param.n_objects)
        yArr = zeros(T,param.n_objects)
        new{T}(param, olist, xArr, yArr,radiiArr)
    end
    PorousStructure(param::MaterialParameters{T},radiiArr::Vector{T}) where T<:Real = PorousStructure(param,radiiArr,zero(T))
end

function generate_porous_structure(outline::O,material::MaterialParameters{T},between_buffer;log=false) where {O<:AbstractOutlineObject,T<:Real}
    ideal_radius = compute_ideal_radius(outline,material)

    #seed = 100
    rng = MersenneTwister()
    radiiArr = ideal_radius*(0.6*rand(rng,material.n_objects) .+ 0.7)
    radiiArr = sort(radiiArr, rev=true)

    ps = PorousStructure(material,radiiArr,between_buffer)

    for ti=1:material.n_objects
        if log; println("attempting to place body #",ti,"..."); end

        xtemp = 0.0
        ytemp = 0.0
        safe_placement = false
        attempt_ind = 1
        while !(safe_placement)
            ps.xArr[ti],ps.yArr[ti] = choose_random_center(outline,rng)
            copyArraysToCenters!(ps,ti)

            inside_bool = is_inside_outline(ps.olist[ti],outline)
            if log; print('\r',"   attempt #",attempt_ind," checking intersection..."); end
            intersection_bool = is_intersecting_others(ti,ps)
            safe_placement = inside_bool && !intersection_bool

            marked_for_shuffling = inside_bool && intersection_bool
            n_shuffles = 10
            if marked_for_shuffling
                if log; print('\r',"   attempt #",attempt_ind," shuffling..."); end
                for i=1:n_shuffles
                    shuffle_object!(ti,ps.olist)
                end
                copyCentersToArrays!(ps::PorousStructure)
            end
            inside_bool = is_inside_outline(ps.olist[ti],outline)
            intersection_bool = is_intersecting_others(ti,ps)
            safe_placement = inside_bool && !intersection_bool

            attempt_ind += 1
            if attempt_ind > material.n_objects*100
                error("reached attempt threshold while trying to place body #$(ti)")
                break
            end
        end
        if log; println("\n   safely placed circle #",ti); end
    end

    computed_vf = compute_volume_fraction(ps,outline)
    if log 
        println()
        println("entered volume fraction:  ",ps.param.expected_volume_fraction)
        println("computed volume fraction: ",computed_vf)
    end

    return ps
end

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

function compute_ideal_radius(outline::O,material::MaterialParameters{T}) where {T<:Real,O<:AbstractOutlineObject}
    area = compute_outline_area(outline)
    return sqrt(area * material.expected_volume_fraction / (pi*material.n_objects))
end

function is_inside_outline(fo::FillingCircle{T},outline::OutlineCircle{T}) where T<:Real
    outline_buffer_radius = (1 + outline.buffer_percent/100)*outline.radius
    furthest_point = fo.radius + sqrt((fo.center.x-outline.center.x)^2 + (fo.center.y-outline.center.y)^2)
    return (furthest_point < outline_buffer_radius ? true : false)
end
function is_inside_outline(fo::FillingCircle{T},outline::OutlineRectangle{T}) where T<:Real
    length = outline.p2.x - outline.p1.x 
    width  = outline.p2.y - outline.p1.y

    # check top
    if (fo.center.y + fo.radius) > outline.p2.y + (outline.buffer_percent/100)*width
        return false
    # check bottom
    elseif (fo.center.y - fo.radius) < outline.p1.y - (outline.buffer_percent/100)*width
        return false
    end
    # check right
    if (fo.center.x + fo.radius) > outline.p2.x + (outline.buffer_percent/100)*length
        return false
    # check left
    elseif (fo.center.x - fo.radius) < outline.p1.x - (outline.buffer_percent/100)*length
        return false
    end

    return true
end
function is_inside_outline(fo::FillingCircle{T},outline::OutlinePolygon{T}) where T<:Real
    return is_inside_polygon(outline.pList, fo.center)
end

function choose_random_center(outline::OutlineCircle{T},rng) where T<:Real
    θ = 2*pi*rand(rng)
    r = outline.radius*rand(rng)
    x = outline.center.x + r*cos(θ)
    y = outline.center.y + r*sin(θ)
    return x,y
end
function choose_random_center(outline::OutlineRectangle{T},rng) where T<:Real
    length = outline.p2.x - outline.p1.x 
    width  = outline.p2.y - outline.p1.y
    x = length*rand(rng) + outline.p1.x
    y = width*rand(rng) + outline.p1.y
    return x,y
end
function choose_random_center(outline::OutlinePolygon{T},rng) where T<:Real
    length = outline.p2_bound.x - outline.p1_bound.x 
    width  = outline.p2_bound.y - outline.p1_bound.y
    x = length*rand(rng) + outline.p1_bound.x
    y = width*rand(rng) + outline.p1_bound.y
    return x,y
end

function is_intersecting_others(ind::Int,ps::PorousStructure)
    if ind > 1
        for ti = 1:(ind-1)
            is_intersecting = is_circle1_intersecting_circle2(ps.olist[ind],ps.olist[ti])
            if is_intersecting == true
                return true
            end
        end
    end

    return false
end

function is_circle1_intersecting_circle2(fo1::F,fo2::F) where F<:FillingCircle
    distance = sqrt((fo2.center.x - fo1.center.x)^2 + (fo2.center.y - fo1.center.y)^2)
    upper_limit = (1 + (fo1.buffer_percent + fo2.buffer_percent)/100)*(fo1.radius + fo2.radius)
    return (distance < upper_limit ? true : false)
end

function compute_volume_fraction(ps::PorousStructure,outline::O) where O<:AbstractOutlineObject
    true_area = compute_outline_area(outline)
    exp_area = 0.0
    for ti=1:ps.param.n_objects
        exp_area += 4*ps.olist[ti].radius^2
    end

    return exp_area/true_area 
end

function compute_outline_area(outline::OutlineCircle{T}) where T<:Real
    return pi*outline.radius^2
end
function compute_outline_area(outline::OutlineRectangle{T}) where T<:Real
    return (outline.p2.x - outline.p1.x)*(outline.p2.y - outline.p1.y)
end
function compute_outline_area(outline::OutlinePolygon{T}) where T<:Real
    n_points = length(outline.pList)
    area = zero(T)
    # first n_points segments (out of n_points + 1 total)
    for ti=1:(n_points-1)
        x0 = outline.pList[ti].x;   y0 = outline.pList[ti].y
        x1 = outline.pList[ti+1].x; y1 = outline.pList[ti+1].y
        
        area += x0*y1 - x1*y0
    end
    # last segment
    x0 = outline.pList[n_points].x;   y0 = outline.pList[n_points].y
    x1 = outline.pList[1].x; y1 = outline.pList[1].y
    area += x0*y1 - x1*y0

    return abs(area)/2
end

function check_vf(volume_fraction)
    if volume_fraction > 0.8
        error(
            "circle packing with volume_fraction = ",
            volume_fraction," is theoretically impossible")
    elseif volume_fraction > 0.7
        @warn string(
            "circle packing with volume_fraction = ",
            volume_fraction," is unlikely")
    end
end

function copyArraysToCenters!(ps::PorousStructure)
    for ti=1:ps.param.n_objects
        ps.olist[ti].center.x = ps.xArr[ti]
        ps.olist[ti].center.y = ps.yArr[ti]
    end
    nothing
end
function copyArraysToCenters!(ps::PorousStructure,ind::Int)
    ps.olist[ind].center.x = ps.xArr[ind]
    ps.olist[ind].center.y = ps.yArr[ind]
    nothing
end

function copyCentersToArrays!(ps::PorousStructure)
    for ti=1:ps.param.n_objects
        ps.xArr[ti] = ps.olist[ti].center.x
        ps.yArr[ti] = ps.olist[ti].center.y
    end
    nothing
end

end # module
