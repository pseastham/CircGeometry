module CircGeometry

import Random: MersenneTwister

abstract type AbstractFillingObject end
abstract type AbstractOutlineObject end

export MaterialParameters,
       OutlineCircle,
       generate_porous_structure,
       write_circ

mutable struct Point{T}
    x::T
    y::T
end

struct OutlineCircle{T} <: AbstractOutlineObject
    radius::T
    center::Point{T}
end

struct OutlinePolygon{T} <: AbstractOutlineObject
    pList::Vector{Point{T}}
end

struct FillingCircle{T} <: AbstractFillingObject
    radius::T
    center::Point{T}
end

struct MaterialParameters{T}
    outer_buffer_percent::T             # percent buffer allowed for small circles to exceed exact circle
    between_buffer_percent::T           # percent buffer allowed between small circles
    expected_volume_fraction::T
    n_objects::Int
end

struct PorousStructure{T}
    param::MaterialParameters{T}
    olist::Vector{FillingCircle{T}}
    xArr::Vector{T}
    yArr::Vector{T}
    radiiArr::Vector{T}

    function PorousStructure(param::MaterialParameters{T},radiiArr::Vector{T}) where T<:Real
        olist = [FillingCircle(radiiArr[ti],Point(zero(T),zero(T))) for ti=1:param.n_objects]
        xArr = zeros(T,param.n_objects)
        yArr = zeros(T,param.n_objects)
        new{T}(param, olist, xArr, yArr,radiiArr)
    end
end

function generate_porous_structure(outline::O,material::MaterialParameters{T};log=false) where {O<:AbstractOutlineObject,T<:Real}
    ideal_radius = compute_ideal_radius(outline,material)

    seed = 100
    rng = MersenneTwister(seed)
    radiiArr = ideal_radius*(0.6*rand(rng,material.n_objects) .+ 0.7)

    # sort radiiArr so that biggest circles are placed first
    radiiArr = sort(radiiArr, rev=true)

    ps = PorousStructure(material,radiiArr)

    safeind = 1
    for ti=1:material.n_objects
        if log; println("attempting to place body #",ti,"..."); end

        safe_placement = false

        xtemp = 0.0
        ytemp = 0.0
        safeind = 1
        while !(safe_placement)
            # randomly choose centers
            θ = 2*pi*rand(rng)
            r = rand(rng)
            xtemp = outline.center.x + r*outline.radius*cos(θ)
            ytemp = outline.center.y + r*outline.radius*sin(θ)

            # check that small circles don't exceed exact circle + buffer
            inside_bool = is_inside_outline(safeind,xtemp,ytemp,ps,outline)
            # check that circles aren't intersecting any previous circles
            if log; print('\r',"   attempt #",safeind," checking intersection..."); end

            intersection_bool = is_intersecting_others(
                ti,ps.param.between_buffer_percent,
                ps.xArr,ps.yArr,ps.radiiArr)
            safe_placement = inside_bool && !intersection_bool
            safeind += 1
            if safeind > 1000
                error("reached attempt threshold while trying to place body #$(ti)")
                break
            end
        end

        ps.olist[ti].center.x = xtemp
        ps.olist[ti].center.y = ytemp
        ps.xArr[ti] = xtemp
        ps.yArr[ti] = ytemp
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

function compute_ideal_radius(outline::OutlineCircle,material::MaterialParameters{T}) where T<:Real
    return sqrt(outline.radius^2 * material.expected_volume_fraction / material.n_objects)
end

function is_inside_outline(ind::Int,x::T,y::T,ps::PorousStructure{T},outline::OutlineCircle{T}) where T<:Real
    buffer_radius = (1 + ps.param.outer_buffer_percent/100)*outline.radius
    furthest_point = outline.radius + sqrt((x-outline.center.x)^2 + (y-outline.center.y)^2)
    return (furthest_point < buffer_radius ? true : false)
end

#function is_inside_exact_circle_buffer(buffer_percent,x,y,radius,true_circle_radius)
#    buffer_radius = (1 + buffer_percent/100)*true_circle_radius
#    furthest_point = radius + sqrt(x^2 + y^2)
#    return (furthest_point < buffer_radius ? true : false)
#end

function is_intersecting_others(ind,buffer_percent,xArr,yArr,radiiArr)
    if ind > 1
        for ti = (ind-1):-1:1
            is_intersecting = is_circle1_intersecting_circle2(
                buffer_percent,
                xArr[ind],yArr[ind],radiiArr[ind],
                xArr[ti],yArr[ti],radiiArr[ti])
            if is_intersecting == true
                return true
            end
        end
    end

    return false
end

function is_circle1_intersecting_circle2(buffer_percent,x1,y1,r1,x2,y2,r2)
    distance = sqrt((x2-x1)^2 + (y2-y1)^2)
    return (distance < (1 + 2*buffer_percent/100)*(r1+r2) ? true : false)
end

function compute_volume_fraction(radiiArr,true_circle_radius)
    nbodies = length(radiiArr)
    true_area = 4*true_circle_radius^2
    area = 0
    for ti=1:nbodies
        area += 4*radiiArr[ti]^2
    end

    return area/true_area
end
function compute_volume_fraction(ps::PorousStructure,outline::O) where O<:AbstractOutlineObject
    true_area = 4*outline.radius^2
    exp_area = 0.0
    for ti=1:ps.param.n_objects
        exp_area += 4*ps.olist[ti].radius^2
    end

    return exp_area/true_area 
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

end # module
