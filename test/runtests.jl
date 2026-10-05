using ComputationalMechanics
using Test
using Random

Random.seed!(123)

@testset "ComputationalMechanics.jl" begin
    @testset "Types" include("test_types.jl")
    @testset "Processes" include("test_process.jl")
    @testset "Inference" include("test_inference.jl")
    @testset "Plots" include("test_plots.jl")
end
