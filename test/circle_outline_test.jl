using CircGeometry, Test

circNames = ["test_circle","test_rect","test_poly"]

# test circle outline
outer_buffer = 5.0
between_buffer = 5.0
vf = 0.4
n_bodies = 50
material = MaterialParameters(vf,n_bodies)
outline = OutlineCircle(1.0,CircGeometry.Point(0.0,0.0),outer_buffer)
ps = generate_porous_structure(
    outline,material,between_buffer;log=false)

write_circ(circNames[1],ps)
vf_exp = CircGeometry.compute_volume_fraction(ps,outline)

# test rectangle outline
outline = OutlineRectangle(
    CircGeometry.Point(-2.0,0.0),
    CircGeometry.Point(1.0,2.0),
    outer_buffer)
@test (CircGeometry.compute_outline_area(outline) == 6.0)
ps = generate_porous_structure(
    outline,material,between_buffer;log=false)
write_circ(circNames[2],ps)
vf_exp = CircGeometry.compute_volume_fraction(ps,outline)

# test arbitrary polygon outline
outline = OutlinePolygon([
    CircGeometry.Point(-1.0,0.0),
    CircGeometry.Point(1.0,0.0),
    CircGeometry.Point(1.0,2.0),
    CircGeometry.Point(0.0,1.0),
    CircGeometry.Point(-1.0,2.0)])
@test (CircGeometry.compute_outline_area(outline) == 3.0)
ps = generate_porous_structure(
    outline,material,between_buffer;log=false)
write_circ(circNames[3],ps)
vf_exp = CircGeometry.compute_volume_fraction(ps,outline)

for ti=1:length(circNames)
    rm(string(circNames[ti],".circ"))
end