function LJForceMagnitude(r::T,d::T) where T<:Real
    return ( r > d ? zero(T) : 2*d/r^2*(1 - d/r) )
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

function compute_repulsion(olist)
    n_objects = length(olist)

    FXarr = zeros(n_objects)
    FYarr = zeros(n_objects)

    for ti=1:Nparticles, tj=(ti+1):Nparticles       # takes advantage of force anti-symmetry
        Δx = olist[tj].center.x - olist[ti].center.x
        Δy = olist[tj].center.y - olist[ti].center.y

        d = olist[ti].radius + olist[tj].radius + (1 + olist[ti].buffer_percent + olist[tj].buffer_percent)/100

        fx,fy = ForceCalculation(d,Δx,Δy)
        FXarr[ti] += fx; FYarr[ti] += fy
        FXarr[tj] -= fx; FYarr[tj] -= fy
    end

    return FXarr, FYarr
end

function shuffle_particles!(olist)
    fX,fY = compute_repulsion(olist)
    for ti=1:data.n_particles
        olist[ti].center.x += fX[ti]*0.1
        olist[ti].center.y += fY[ti]*0.1
    end
    nothing
end
