using Documenter, CircGeometry

push!(LOAD_PATH,"../src/")

makedocs(;
    modules=[CircGeometry],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/pseastham/CircGeometry.jl/blob/{commit}{path}#L{line}",
    sitename="CircGeometry.jl",
    authors="Patrick Eastham",
    assets=String[],
)

deploydocs(;
    repo="github.com/pseastham/CircGeometry.jl",
)
