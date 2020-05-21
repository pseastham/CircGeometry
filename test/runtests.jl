using SafeTestsets

@time begin
    @time @safetestset "Check Position Tests" begin include("position_checking_test.jl") end
    @time @safetestset "IO Tests" begin include("io_test.jl") end
    @time @safetestset "Full Run Tests" begin include("full_run_test.jl") end
    @time @safetestset "Wall Repulsion Tests" begin include("wall_repulsion_test.jl") end
    @time @safetestset "Examples Test" begin include("examples_test.jl") end
end
