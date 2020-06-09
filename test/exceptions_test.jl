using CircGeometry, Test

# error for too large vf
vf = 0.9
n_bodies = 400
material = MaterialParameters(vf,n_bodies)

radius = 1.5
center = Point(-0.5,1.0)
outline = OutlineCircle(radius,center)

between_buffer = compute_between_buffer(outline,material)
@test_throws ErrorException generate_porous_structure(outline,material,between_buffer;log=false)

# error for max iterations reached
vf = 0.79
material = MaterialParameters(vf,n_bodies)
between_buffer = 100
@test_throws MethodError generate_porous_structure(outline,material,between_buffer;log=false)