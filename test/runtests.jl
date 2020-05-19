using SafeTestsets

@time begin
    @time @safetestset "Check Position Tests" begin include("position_checking_test.jl") end
    @time @safetestset "Full Run Tests" begin include("full_run_test.jl") end
end
