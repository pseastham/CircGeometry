using CircGeometry, Test

# colors
julia_blue = :royalblue
julia_green = :forestgreen
julia_red = :brown3
julia_purple = :mediumorchid3
colors = [julia_red,julia_purple,julia_green]

vf = 0.5
n_bodies = 80
material = MaterialParameters(vf,n_bodies)

radius = 0.65
center = Point(0.0,0.0)
outline = OutlineCircle(radius,center)

between_buffer = 15.0
ps1 = generate_porous_structure(outline,material,between_buffer;log=true)
ps2 = generate_porous_structure(outline,material,between_buffer;log=true)
ps3 = generate_porous_structure(outline,material,between_buffer;log=true)

# translate
CircGeometry.translate!(ps1,-0.8,0.0)
CircGeometry.translate!(ps2,0.8,0.0)
CircGeometry.translate!(ps3,0.0,1.2)

# save
save_image("julia_logo.svg",[ps1,ps2,ps3],colors;alpha=1.0) 

rm("julia_logo.svg")
