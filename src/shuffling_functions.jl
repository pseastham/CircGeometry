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

function shuffle_object!(ind::Int,olist)
    fX,fY = compute_repulsion(ind,olist)
    olist[ind].center.x += fX[ind]*1e-6
    olist[ind].center.y += fY[ind]*1e-6
    nothing
end
