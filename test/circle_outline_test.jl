using CircGeometry, Test

outer_buffer = 5.0
between_buffer = 5.0
vf = 0.3
n_bodies = 100
material = MaterialParameters(vf,n_bodies)
outline = OutlineCircle(1.0,CircGeometry.Point(0.0,0.0),outer_buffer)
ps = generate_porous_structure(outline,material,between_buffer;log=true)

write_circ("test",ps)

vf_exp = CircGeometry.compute_volume_fraction(ps,outline)
@test (vf_exp - vf)/vf < 0.1
