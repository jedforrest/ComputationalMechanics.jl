@testset "Inference" begin
    gmp = golden_mean_process(0.6)

    N = 10_000
    y = simulate(gmp, N)
    @test !occursin("11", y)  # machine does not allow '11'

    inference = infer_machine(CSSR(), y,
        max_history=2,
        min_count=5,
        alpha = 0.001
    )

    @test inference.alg isa CSSR
    @test inference.sequence_length == N
    @test inference.max_history == 2
    @test inference.min_count == 5
    @test inference.alpha == 0.001

    machine = inference.machine
    @test num_states(machine) == 2
    @test num_transitions(machine) == 3
end

# TODO test with emics examples
