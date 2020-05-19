using CircGeometry, Test

between_buffer = 5.0
vf = 0.4
n_bodies = 50

# test circle outline
material = MaterialParameters(vf,n_bodies)
outline = OutlineCircle(1.0,Point(0.0,0.0))
ps = generate_porous_structure(outline,material,between_buffer;log=false)
vf_exp = compute_volume_fraction(ps,outline)

# test rectangle outline
outline = OutlineRectangle(Point(-2.0,0.0),Point(1.0,2.0))
@test CircGeometry.compute_outline_area(outline) == 6.0
ps = generate_porous_structure(outline,material,between_buffer;log=false)
vf_exp = compute_volume_fraction(ps,outline)

# test polygon outline
outline = OutlinePolygon([Point(-1.0,0.0),Point(1.0,0.0),
            Point(1.0,2.0),Point(0.0,1.0),Point(-1.0,2.0)])
@test CircGeometry.compute_outline_area(outline) == 3.0
ps = generate_porous_structure(outline,material,between_buffer;log=false)
vf_exp = compute_volume_fraction(ps,outline)