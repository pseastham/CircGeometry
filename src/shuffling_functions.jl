function LJForceMagnitude(r::T,d::T) where T<:Real
    if r > d 
        return zero(T)
    elseif r < 0.8*d
        return zero(T)
    else
        return 2*d/r^2*(1 - d/r)
    end
end

function ForceCalculation(d::T,Δx::T,Δy::T) where T<:Real
    r = sqrt(Δx^2 + Δy^2)
    tx = Δx/r
    ty = Δy/r

    LJmag = LJForceMagnitude(r,d)

    Fx = tx*LJmag
    Fy = ty*LJmag

    return Fx,Fy
end 

function compute_repulsion(ind::Int,olist)
    FXarr = zeros(ind)
    FYarr = zeros(ind)

    for ti=1:ind, tj=(ti+1):ind       # takes advantage of force anti-symmetry
        Δx = olist[tj].center.x - olist[ti].center.x
        Δy = olist[tj].center.y - olist[ti].center.y
        d = olist[ti].radius + olist[tj].radius + 
            (1 + olist[ti].buffer_percent + olist[tj].buffer_percent)/100

        fx,fy = ForceCalculation(d,Δx,Δy)
        FXarr[ti] += fx; FYarr[ti] += fy
        FXarr[tj] -= fx; FYarr[tj] -= fy
    end

    return FXarr, FYarr
end

function compute_wall_repulsion(ind,olist,wlist)
    FX = 0.0
    FY = 0.0

    for tw=1:length(wlist)
        pointOnWall = NearestPoint(olist[ind].center,wlist[tw])
        if isInLine(wlist[tw],pointOnWall)
            Δx = pointOnWall.x - olist[ind].center.x     # might be pointing the wrong way...
            Δy = pointOnWall.y - olist[ind].center.y

            d = olist[ind].radius + wlist[tw].thickness/2

            fx,fy = ForceCalculation(d,Δx,Δy)
            FX += fx
            FY += fy
        end
    end

    return FX, FY
end

function shuffle_object!(ind::Int,olist,wlist)
    fXr,fYr = compute_repulsion(ind,olist)
    fXw,fYw = compute_wall_repulsion(ind,olist,wlist)
    olist[ind].center.x += (fXr[ind] + fXw)*1e-6
    olist[ind].center.y += (fYr[ind] + fYw)*1e-6
    nothing
end

#    NearestPoint!(point,node,wall)
#
#Compute nearest point to object on LineWall and CircleWall 
function NearestPoint!(point::Point{T},node::Point{T},wall::LineWall) where T<:Real
    px=node.x; py=node.y

    Ax=wall.nodes[1].x; Ay=wall.nodes[1].y
    Bx=wall.nodes[2].x; By=wall.nodes[2].y

    bx=px-Ax; by=py-Ay
    ax=Bx-Ax; ay=By-Ay

    ℓ2 = ax^2+ay^2

    dotprod = ax*bx + ay*by

    point.x = dotprod*ax/ℓ2 + Ax
    point.y = dotprod*ay/ℓ2 + Ay

    nothing
end
function NearestPoint!(point::Point{T},node::Point{T},wall::CircleWall) where T<:Real
    px=node.x; py=node.y
    cx=wall.center.x; cy=wall.center.y
    r = wall.radius
    θ = atan(py-cy,px-cx)

    point.x = cx + r*cos(θ)
    point.y = cy + r*sin(θ)

    nothing
end
function NearestPoint(node::Point{T},wall::W) where {T<:Real,W<:AbstractWall}
    point = Point(0.0,0.0)
    NearestPoint!(point,node,wall)
    return point
end

# function to determine whether quadrature node (sx,sy) is within line
function isInLine(wall::LineWall{T},point::Point{T}) where T<:Real
    return onSegmentWithBuffer(wall.nodes[1],point,wall.nodes[2],wall.thickness/2)     # onSegment is located in isInside.jl
end
# note: s is input only to make all arguments for isInLine the same
function isInLine(wall::CircleWall{T},point::Point{T}) where T<:Real
    cx = wall.center.x; cy=wall.center.y
    val = abs(wall.radius - sqrt((cx-point.x)^2 + (cy-point.y)^2))
    TOL = 1e-12
    return (val < TOL ? true : false)
end

function onSegmentWithBuffer(p::Point{T},q::Point{T},r::Point{T},buffer::T) where T<:Real
    maxX = (p.x >= r.x ? p.x : r.x) + buffer
    minX = (p.x >= r.x ? r.x : p.x) - buffer
    maxY = (p.y >= r.y ? p.y : r.y) + buffer
    minY = (p.y >= r.y ? p.y : r.y) - buffer
  
    if (q.x <= maxX && q.x >= minX && q.y <= maxY && q.y >= minY)
        return true
    else
      return false
    end
  end