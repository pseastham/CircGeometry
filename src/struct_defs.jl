abstract type AbstractFillingObject end
abstract type AbstractOutlineObject end
abstract type AbstractWall end

mutable struct Point{T}
    x::T
    y::T
end

# do we need thickness for anything?
struct LineWall{T} <: AbstractWall
    nodes::Vector{Point{T}}     # 2 points, defining start and end
    thickness::T                
    n::Vector{T}                # normal unit vector of wall
    t::Vector{T}                # tangent unit vector of wall

    function LineWall(n1::Point{T},n2::Point{T},thickness::T) where T<:Real    
        n = zeros(Float64,2); t = zeros(Float64,2)
    
        # compute wall length
        WL = sqrt((n2.x - n1.x)^2 + (n2.y - n1.y)^2)
    
        # comute tangent
        t[1] = (n2.x - n1.x)/WL
        t[2] = (n2.y - n1.y)/WL
    
        n[1] = -t[2]
        n[2] =  t[1]

        nodes = [n1,n2]
    
        return new{T}(nodes,thickness,n,t)
    end
    LineWall(n1,n2) = LineWall([n1,n2],0.0)
end

struct CircleWall{T} <: AbstractWall
    center::Point{T}          # point that defines center
    radius::T                 # radius of circle
    thickness::T              # gives circle curve "area"

    function CircleWall(center::Point{T},radius::T) where T<:Real
        return new{T}(center,radius,zero(T))
    end
end

struct OutlineCircle{T} <: AbstractOutlineObject
    radius::T
    center::Point{T}
    wlist::Vector{CircleWall{T}}

    function OutlineCircle(radius::T,center::Point{T}) where T<:Real
        wlist = [CircleWall(center,radius)]
        return new{T}(radius,center,wlist)
    end
end

struct OutlineRectangle{T} <: AbstractOutlineObject
    p1::Point{T}                # lower left point
    p2::Point{T}                # upper right point
    wlist::Vector{LineWall{T}}

    function OutlineRectangle(p1::Point{T},p2::Point{T}) where T<:Real
        wlist = [LineWall(Point(p2.x,p2.y),Point(p1.x,p2.y)),            # top
                 LineWall(Point(p1.x,p1.y),Point(p2.x,p1.y)),            # bottom
                 LineWall(Point(p1.x,p2.y),Point(p1.x,p1.y)),            # left
                 LineWall(Point(p2.x,p1.y),Point(p2.x,p2.y))]            # right
        return new{T}(p1,p2,wlist)
    end
end

struct OutlinePolygon{T} <: AbstractOutlineObject
    pList::Vector{Point{T}}
    p1_bound::Point{T}
    p2_bound::Point{T}
    wlist::Vector{LineWall{T}}

    function OutlinePolygon(pList::Vector{Point{T}}) where T<:Real
        n_objects = length(pList)
        maxX = -10_000.0; minX = -maxX
        maxY = maxX; minY = -maxX
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
        wlist = Array{LineWall}(undef,n_objects)
        for ti=1:n_objects-1
            wlist[ti] = LineWall(pList[ti],pList[ti+1],zero(T))
        end
        wlist[n_objects] = LineWall(pList[n_objects],pList[1],zero(T))

        return new{T}(pList,p1_bound,p2_bound,wlist)
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
end