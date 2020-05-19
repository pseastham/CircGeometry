function LJForceMagnitude(r::T,d::T) where T<:Real
    if r > d || r < 0.8*d
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

function compute_body_repulsion(ind::Int,olist)
    FX = 0.0
    FY = 0.0

    for ti=1:(ind-1)
        Δx = olist[ind].center.x - olist[ti].center.x
        Δy = olist[ind].center.y - olist[ti].center.y
        d = olist[ti].radius + olist[ind].radius + 
            (1 + olist[ti].buffer_percent + olist[ind].buffer_percent)/100

        fx,fy = ForceCalculation(d,Δx,Δy)
        FX += fx; FY += fy
    end

    return FX, FY
end

function compute_wall_repulsion(ind,olist,wlist)
    FX = 0.0
    FY = 0.0

    for tw=1:length(wlist)
        pointOnWall = get_nearest_point(olist[ind].center,wlist[tw])
        if is_point_in_wall(pointOnWall,wlist[tw])
            Δx = pointOnWall.x - olist[ind].center.x
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
    fXr,fYr = compute_body_repulsion(ind,olist)
    fXw,fYw = compute_wall_repulsion(ind,olist,wlist)
    olist[ind].center.x += (fXr + fXw)*1e-6
    olist[ind].center.y += (fYr + fYw)*1e-6
    nothing
end