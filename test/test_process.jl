@testset "Golden mean process information measures" begin
    p = 0.5
    gmp = golden_mean_process(p)

    @test num_states(gmp) == 2
    @test statistical_complexity(gmp) ≈ 0.9183 atol = 1e-4
    @test entropy_rate(gmp) ≈ 0.6666 atol = 1e-4

    pi_a(p) = 1.0 / (2.0 - p)
    pi_b(p) = (1.0 - p) / (2.0 - p)

    dist = stationary_distribution(gmp)
    @test dist["A"] ≈ pi_a(p) && dist["B"] ≈ pi_b(p)

    p = 0.2
    gmp = golden_mean_process(p)
    dist = stationary_distribution(gmp)
    @test dist["A"] ≈ pi_a(p) && dist["B"] ≈ pi_b(p)

    hist = histories(gmp)
    @test hist == Dict("0" => 1, "1" => 2)
end


@testset "Other synthetic processes information measures" begin
    # should be the same as golden_mean_process
    p = 0.8
    ep = even_process(p)
    gmp = golden_mean_process(p)

    @test statistical_complexity(ep) == statistical_complexity(gmp)
    @test entropy_rate(ep) == entropy_rate(gmp)

    bcp = biased_coin_process(0.7)
    @test statistical_complexity(bcp) ≈ 0

    pp = periodic_process(1:5)
    @test entropy_rate(pp) ≈ 0
end


@testset "Simulations" begin
    ep = even_process(0.6)

    @test simulate(String, ep, 10) isa String
    @test simulate(Vector, ep, 10) isa Vector{Char}

    seq = simulate(ep, 1000)
    @test length(seq) == 1000
    @test !occursin("010", seq)  # no odd sequences of 1s

    ep.startstate = "B"
    seq = simulate(ep, 10)
    @test seq[1] == '1'  # state B always returns 1
end


@testset "Distributions" begin
    fhp = feldman_hanna_process()
    P = transition_matrix(fhp)

    exact_P = [
        3//16   13//16  0       0       0      0      0
        0       0       3//16   13//16  0      0      0
        0       0       0       0       9//16  7//16  0
        0       0       15//16  1//16   0      0      0
        9//16   0       0       0       0      0      7//16
        0       0       1//4    3//4    0      0      0
        0       0       3//4    1//4    0      0      0
    ]
    @test P == exact_P

    # TODO check external source that distribution is correct
    exact_dist = Dict(
        "BB"   => 0.189426,
        "BA"   => 0.274592,
        "BAAB" => 0.0675754,
        "AAAB" => 0.0868826,
        "BAA"  => 0.154458,
        "BAB"  => 0.120134,
        "AAA"  => 0.106932,
    )
    dist = stationary_distribution(fhp)
    for label in labels(fhp)
        @test dist[label] ≈ exact_dist[label] atol = 1e-6
    end
end
