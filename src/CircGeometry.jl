module CircGeometry

abstract type AbstractPlacementObject end
abstract type AbstractCircle end

mutable struct Point{T}
    x::T
    y::T
end

struct PlacementCircle{T} <: AbstractPlacementObject
    radius::T
    center::Point{T}
end

struct MaterialParameters{T}
    outer_buffer_percent::T
    between_buffer_percent::T
end


end # module
