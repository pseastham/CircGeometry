abstract type AbstractFillingObject end
abstract type AbstractOutlineObject end

mutable struct Point{T}
    x::T
    y::T
end

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
