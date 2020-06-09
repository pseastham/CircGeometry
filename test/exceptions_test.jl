using CircGeometry, Test

# error for too large vf
vf = 0.9
@test_throws ErrorException CircGeometry.check_vf(0.85)

# error for max iterations reached
vf = 0.79
n_bodies = 400
material = MaterialParameters(vf,n_bodies)
radius = 1.5
center = Point(-0.5,1.0)
outline = OutlineCircle(radius,center)
between_buffer = 100
@test_throws MethodError generate_porous_structure(outline,material,between_buffer;log=false)