using SafeTestsets

@time begin
    @time @safetestset "Circle Outline Tests" begin include("circle_outline_test.jl") end
end
