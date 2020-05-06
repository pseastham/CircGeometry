module CircGeometry

mutable struct Point{T}
    x::T
    y::T
end

include("shuffling_functions.jl")
include("struct_defs.jl")
include("is_inside_functions.jl")
include("main_functions.jl")
include("io.jl")

export MaterialParameters,
       OutlineCircle,
       OutlineRectangle,
       OutlinePolygon,
       generate_porous_structure,
       write_circ,
       csv_to_polygon,
       save_image,
       Point

end # module
