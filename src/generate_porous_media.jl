import Random
using Plots #plots only for debugging

pyplot(aspect_ratio=:equal)

"""
    generate_porous_media_file(fileName,nbodies,volume_fraction,true_circle_radius)
"""
function generate_porous_media_file(fileName::String,nbodies,volume_fraction,true_circle_radius)
    outer_buffer_percent = 5     # percent buffer allowed for small circles to exceed exact circle
    between_buffer_percent = 5   # percent buffer allowed between small circles

    run(`rm -rf figures`)
    run(`mkdir -p figures`)
    colorArr=[:blue,:red,:green,:purple,:pink]

    if volume_fraction > 0.8
        error(
            "circle packing with volume_fraction = ",
            volume_fraction," is theoretically impossible")
    elseif volume_fraction > 0.7
        @warn string(
            "circle packing with volume_fraction = ",
            volume_fraction," is unlikely")
    end

    radiiArr = zeros(nbodies)
    xArr     = zeros(nbodies)
    yArr     = zeros(nbodies)

    # compute expected radii of circles
    circle_radius = compute_ideal_radii(true_circle_radius,volume_fraction,nbodies)

    # initial random number generator (seed for testing)
    seed = 100
    rng = Random.MersenneTwister(seed)

    # generate radii of bodies
    for ti = 1:nbodies
        num = 0.6*rand(rng) + 0.7
        radiiArr[ti] = num*circle_radius
    end

    # sort radiiArr so that biggest circles are placed first
    radiiArr = sort(radiiArr, rev=true)

    safeind = 1
    for ti=1:nbodies
        println("attempting to place body #",ti,"...")
        safe_placement = false

        xtemp = 0.0
        ytemp = 0.0
        safeind = 1
        while !(safe_placement)
            plot_radius = 1.1*(1 + outer_buffer_percent/100)*true_circle_radius
            p = plot(
                xlim=(-plot_radius,plot_radius),
                ylim=(-plot_radius,plot_radius),
                title="placed $(ti-1) bodies, attempt #$(safeind) for body #$(ti)")
            # randomly choose centers
            θ = 2*pi*rand(rng)
            r = rand(rng)
            xtemp = r*true_circle_radius*cos(θ)
            ytemp = r*true_circle_radius*sin(θ)

            # visual debugging
            nθ = 40
            θarr = 0:2*pi/(nθ-1):2*pi
            xArr[ti] = xtemp
            yArr[ti] = ytemp
            for tj = 1:ti
                plot!(p,
                    xArr[tj] .+ radiiArr[tj]*cos.(θarr),
                    yArr[tj] .+ radiiArr[tj]*sin.(θarr),
                    label="",color=colorArr[mod(tj,length(colorArr)-1)+1])
                plot!(p,
                    xArr[tj] .+ (1 + between_buffer_percent/100)*radiiArr[tj]*cos.(θarr),
                    yArr[tj] .+ (1 + between_buffer_percent/100)*radiiArr[tj]*sin.(θarr),
                    label="",color=colorArr[mod(tj,length(colorArr)-1)+1],linestyle=:dash)
                plot!(p,
                    true_circle_radius*cos.(θarr),
                    true_circle_radius*sin.(θarr),
                    label="",color=:black)
                plot!(p,
                    true_circle_radius*(1 + outer_buffer_percent/100)*cos.(θarr),
                    true_circle_radius*(1 + outer_buffer_percent/100)*sin.(θarr),
                    label="",color=:black,linestyle=:dash)
            end
            savefig(p,"figures/test_$(lpad(ti, 4, '0'))_$(lpad(safeind, 4, '0')).png")

            # check that small circles don't exceed exact circle + buffer
            inside_bool = is_inside_exact_circle_buffer(
                outer_buffer_percent,
                xArr[ti],yArr[ti],radiiArr[ti],
                true_circle_radius)
            # check that circles aren't intersecting any previous circles
            print('\r',"   attempt #",safeind," checking intersection...")
            intersection_bool = is_intersecting_others(
                ti,between_buffer_percent,
                xArr,yArr,radiiArr)
            safe_placement = inside_bool && !intersection_bool
            safeind += 1
            if safeind > 1000
                error("reached attempt threshold while trying to place body #$(ti)")
                break
            end
        end

        xArr[ti] = xtemp
        yArr[ti] = ytemp
        println("\n   safely placed circle #",ti)
    end

    # final print
    plot_radius = 1.1*(1 + outer_buffer_percent/100)*true_circle_radius
    p = plot(
        xlim=(-plot_radius,plot_radius),
        ylim=(-plot_radius,plot_radius))
    nθ = 40
    θarr = 0:2*pi/(nθ-1):2*pi
    for tj = 1:nbodies
        plot!(p,
            xArr[tj] .+ radiiArr[tj]*cos.(θarr),
            yArr[tj] .+ radiiArr[tj]*sin.(θarr),
            label="",color=colorArr[mod(tj,length(colorArr)-1)+1])
        plot!(p,
            xArr[tj] .+ (1 + between_buffer_percent/100)*radiiArr[tj]*cos.(θarr),
            yArr[tj] .+ (1 + between_buffer_percent/100)*radiiArr[tj]*sin.(θarr),
            label="",color=colorArr[mod(tj,length(colorArr)-1)+1],linestyle=:dash)
        plot!(p,
            true_circle_radius*cos.(θarr),
            true_circle_radius*sin.(θarr),
            label="",color=:black)
        plot!(p,
            true_circle_radius*(1 + outer_buffer_percent/100)*cos.(θarr),
            true_circle_radius*(1 + outer_buffer_percent/100)*sin.(θarr),
            label="",color=:black,linestyle=:dash,
            title="all $(nbodies) bodies placed succesfully!")
    end
    savefig(p,"figures/test_$(nbodies)_$(safeind).png")

    println()
    computed_vf =compute_volume_fraction(radiiArr,true_circle_radius)
    println("entered volume fraction:  ",volume_fraction)
    println("computed volume fraction: ",computed_vf)

    println()
    println("creating gif...")
    run(`./create_gif.sh`)

    # output into *.circ file format
    run(`mkdir -p ../geometry-files`)
    filepath = string("../geometry-files/",fileName,".circ")
    open(filepath, "w") do io
        println(io, "# nbods")
        println(io, nbodies)
        println(io, "# data below: radius, xc, yc for each body.")
        for ti=1:nbodies
            println(io, radiiArr[ti])
            println(io, xArr[ti])
            println(io, yArr[ti])
        end
    end


    nothing
end

function compute_ideal_radii(true_circle_radius,volume_fraction,nbodies)
    return sqrt(true_circle_radius^2 * volume_fraction / nbodies)
end

function is_inside_exact_circle_buffer(buffer_percent,x,y,radius,true_circle_radius)
    buffer_radius = (1 + buffer_percent/100)*true_circle_radius
    furthest_point = radius + sqrt(x^2 + y^2)
    return (furthest_point < buffer_radius ? true : false)
end

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
