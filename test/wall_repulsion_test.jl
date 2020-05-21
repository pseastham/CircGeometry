using CircGeometry

center = Point(-0.9,0.0)
p1 = Point(-1.0,-1.0)
p2 = Point(1.0,1.0)

fo = CircGeometry.FillingCircle(0.1,center,10.0)
olist = [fo]
outline = CircGeometry.OutlineRectangle(p1,p2)

Fx,Fy = CircGeometry.compute_wall_repulsion(1,olist,outline.wlist)
bool1 = CircGeometry.is_intersecting_walls(outline,fo)
bool2 = CircGeometry.is_inside_outline(fo,outline)

println()
println("~~~ output ~~~")
println("(Fx,Fy) = ",Fx,",",Fy)
println("is intersecting wall: ",bool1)
println("is inside outline: ",bool2)