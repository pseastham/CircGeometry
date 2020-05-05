module CircGeometry

include("shuffling_functions.jl")

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
    buffer_percent::T
end

struct OutlinePolygon{T} <: AbstractOutlineObject
    pList::Vector{Point{T}}
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
end

function generate_porous_structure(outline::O,material::MaterialParameters{T},between_buffer::T;log=false) where {O<:AbstractOutlineObject,T<:Real}
    ideal_radius = compute_ideal_radius(outline,material)

    seed = 100
    rng = MersenneTwister(seed)
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
            if mark_for_shuffling
                if log; print('\r',"   attempt #",attempt_ind," shuffling..."); end
                for i=1:10          # this should be extended or shortened depending on number of particles
                    shuffle_objects!(ps.olist)
                end
                copyCentersToArrays!(ps::PorousStructure)
                inside_bool = is_inside_outline(ps.olist[ti],outline)
                intersection_bool = is_intersecting_others(ti,ps)
                safe_placement = inside_bool && !intersection_bool
            end

            attempt_ind += 1
            if attempt_ind > 1000
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

function compute_ideal_radius(outline::OutlineCircle,material::MaterialParameters{T}) where T<:Real
    return sqrt(outline.radius^2 * material.expected_volume_fraction / material.n_objects)
end

function is_inside_outline(fo::FillingCircle{T},outline::OutlineCircle{T}) where T<:Real
    outline_buffer_radius = (1 + outline.buffer_percent/100)*outline.radius
    furthest_point = fo.radius + sqrt((fo.center.x-outline.center.x)^2 + (fo.center.y-outline.center.y)^2)
    return (furthest_point < outline_buffer_radius ? true : false)
end

function choose_random_center(outline::OutlineCircle{T},rng) where T<:Real
    θ = 2*pi*rand(rng)
    r = outline.radius*rand(rng)
    x = outline.center.x + r*cos(θ)
    y = outline.center.y + r*sin(θ)
    return x,y
end

function is_intersecting_others(ind::Int,ps::PorousStructure)
    if ind > 1
        for ti = (ind-1):-1:1
            is_intersecting = is_circle1_intersecting_circle2(ps.olist[ind],ps.olist[ti])
            if is_intersecting == true
                return true
            end
        end
    end

    return false
end

#function is_circle1_intersecting_circle2(buffer_percent,x1,y1,r1,x2,y2,r2)
#    distance = sqrt((x2-x1)^2 + (y2-y1)^2)
#    return (distance < (1 + 2*buffer_percent/100)*(r1+r2) ? true : false)
#end
function is_circle1_intersecting_circle2(fo1::F,fo2::F) where F<:FillingCircle
    distance = sqrt((fo2.center.x - fo1.center.x)^2 + (fo2.center.y - fo1.center.y)^2)
    upper_limit = (1 + (fo1.buffer_percent + fo2.buffer_percent)/100)*(fo1.radius + fo2.radius)
    return (distance < upper_limit ? true : false)
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
