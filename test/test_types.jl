@testset "Probability arithmetic" begin
    p = Probability(0.3)
    q = Probability(0.2)

    @test_throws ArgumentError Probability(1.2)

    @test p + q ≈ 0.5
    @test 2q ≈ 0.4
    @test p * q ≈ 0.06
    @test 1 - p ≈ 0.7
    @test (q / p).value ≈ 2. / 3.
end


@testset "Distributions" begin
    dist = Distribution(['A', 'B', 'C'], [0.5, 0.4, 0.1])
    @test eltype(dist) == Pair{Char, Probability}
    dist['D']
    @test dist['D'] == Probability(0)

    dist2 = Distribution([0, 1], [0.5, 0.5]; alphabet=0:5)
    @test dist2[1] == 0.5
    @test length(keys(dist2)) == 6

    @test_throws ArgumentError Distribution([0, 1], [0.5, 0.2])
end


@testset "Transition graph and causal states" begin
    @test_throws ArgumentError Transition(0, 2.0, "A")

    t1 = Transition(0, 0.5, "A")
    t2 = Transition(1, 0.5, "B")
    t3 = Transition(0, 1.0, "A")

    @test_throws ArgumentError CausalState("A", [t1, t3])
    c1 = CausalState("A", [t1, t2])
    c2 = CausalState("B", [t3])

    @test eltype(t1) == Int
    @test eltype(c1) == Int

    states = [c1, c2]
    g = transition_graph(states)
    @test g["A"] == c1
    @test g["A", "B"] == t2

    next_t = sample_next_transition(c1)
    @test next_t in [t1, t2]

    dist = emission_distribution(c1)
    @test sum(values(dist)) ≈ 1.0 atol = 1e-8
end


@testset "EpsilonMachine construction and iteration" begin
    t1 = Transition(0, 0.5, "A")
    t2 = Transition(1, 0.5, "B")
    t3 = Transition(0, 1.0, "A")
    c1 = CausalState("A", [t1, t2])
    c2 = CausalState("B", [t3])
    states = [c1, c2]

    em = EpsilonMachine(states, "A")

    @test em["A"] == c1
    @test eltype(em) == eltype(typeof(em)) == Int

    s = join(Iterators.take(em, 50))
    @test length(s) == 50
    @test !occursin("11", s)  # machine does not allow '11' in this case

    W = transition_matrix(em)
    @test size(W) == (2, 2)

    @test ComputationalMechanics._is_unifilar(em)
end


@testset "Unifilarity detection" begin
    non_unifilar_states = [CausalState("A", [Transition(0, 0.5, "A"), Transition(0, 0.5, "B")])]
    @test_throws ArgumentError EpsilonMachine([0, 1], non_unifilar_states, "A")
end


@testset "Structural statistics" begin
    t1 = Transition(0, 0.5, "A")
    t2 = Transition(1, 0.5, "B")
    t3 = Transition(0, 1.0, "A")
    c1 = CausalState("A", [t1, t2])
    c2 = CausalState("B", [t3])
    states = [c1, c2]
    em = EpsilonMachine(states, "A")

    @test num_states(em) == length(states)
    @test num_transitions(em) == sum(length(s.transitions) for s in states)
    @test alphabet_size(em) == 2
    @test topological_complexity(em) == 1
end
