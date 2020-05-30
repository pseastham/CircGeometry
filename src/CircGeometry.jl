module CircGeometry

include("struct_defs.jl")
include("is_inside_functions.jl")
include("shuffling_functions.jl")
include("main_functions.jl")
include("io.jl")

export MaterialParameters,
       OutlineCircle,
       OutlineRectangle,
       OutlinePolygon,
       generate_porous_structure,
       compute_between_buffer,
       compute_volume_fraction,
       Point,
       translate!

export write_circ,
       csv_to_polygon,
       save_image

end # module
