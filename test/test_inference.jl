gmp = golden_mean_process(0.5)
fhp = feldman_hanna_process()

@testset "Inference" begin
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
    @test eltype(machine) == Char

    # inference should also work on vector sequences
    y_vec = simulate(Vector, gmp, N)
    inference_vec = infer_machine(CSSR(), y_vec,
        max_history=2,
        min_count=5,
        alpha = 0.001
    )
    machine_vec = inference_vec.machine
    @test eltype(machine_vec) == Char  # eltype changes to Char
    @test machine_vec.alphabet == machine.alphabet
    @test machine_vec.startstate == machine.startstate
end

# TODO test with emics examples

@testset "Prediction" begin
    dist = predict(gmp, "1001")
    @test dist['0'] == 1.0 && dist['1'] == 0.0 # last symbol was 1, so next must be 0

    dist = predict(gmp, "1000")
    @test dist['0'] == 0.5 && dist['1'] == 0.5 # last symbol was 0, either is possible

    dist = predict(fhp, "BAAB")
    @test dist['A'] == 0.75 && dist['B'] == 0.25
    dist = predict(fhp, "AAAA")
    @test dist['A'] == 0.1875 && dist['B'] == 0.8125

    @test_throws ErrorException predict(fhp, "1001")
    @test_throws ErrorException predict(fhp, "B")
end


@testset "Filtering" begin
    @test filter_states(gmp, "0") == ["A"]
    @test filter_states(gmp, "0010") == ["A", "A", "B", "A"]
    @test_throws ErrorException filter_states(gmp, "1111") # this is not be a valid sequence

    @test filter_states(fhp, "BAABA") == ["BA", "BAA", "BAAB", "BA"]
    @test filter_states(fhp, "AAAAAAAAAA") == fill("AAA", 8)
    @test isempty(filter_states(fhp, "B"))

    @test_throws ErrorException filter_states(fhp, "BCA")
end
