using CircGeometry, Test

outer_buffer = 5.0
between_buffer = 5.0
vf = 0.3
n_bodies = 2
material = MaterialParameters(outer_buffer,between_buffer,vf,n_bodies)
outline = OutlineCircle(1.0,CircGeometry.Point(1.2,-0.3))
ps = generate_porous_structure(outline,material;log=false)

write_circ("test",ps)

vf_exp = CircGeometry.compute_volume_fraction(ps,outline)
@test (vf_exp - vf)/vf < 0.1
