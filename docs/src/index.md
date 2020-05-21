# CircGeometry.jl Documentation

```@contents
```

## Structures

```@docs
Point{T}
MaterialParameters{T}
OutlineCircle{T}
OutlineRectangle{T}
OutlinePolygon{T}

```

## Functions

```@docs
generate_porous_structure(outline,material,between_buffer;log=false)
compute_between_buffer(outline,material)
compute_volume_fraction(ps,outline)
```

## Input/Output

```@docs
write_circ(file_name,ps)
csv_to_polygon(file_name)
save_image(output_name,ps,outline)
save_image(output_name,circ_file,outline)
```

## Index

```@index
```
