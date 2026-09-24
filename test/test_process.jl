@testset "Golden mean process information measures" begin
    gmp = golden_mean_process(0.5)

    @test num_states(gmp) == 2
    @test statistical_complexity(gmp) ≈ 0.9183 atol = 1e-4
    @test entropy_rate(gmp) ≈ 0.6666 atol = 1e-4

    @test_skip excess_entropy(gmp)  # TODO: not yet implemented
    @test_skip crypticity(gmp)      # TODO: not yet implemented
end


@testset "Even process information measures" begin
    ep = even_process(0.2)

    @test_skip statistical_complexity(ep)
    @test_skip entropy_rate(ep)

    @test_skip excess_entropy(ep)  # TODO: not yet implemented
    @test_skip crypticity(ep)      # TODO: not yet implemented
end


@testset "Biased coin process information measures" begin
    bcp = biased_coin_process(0.7)

    @test_skip statistical_complexity(bcp)
    @test_skip entropy_rate(bcp)

    @test_skip excess_entropy(bcp)  # TODO: not yet implemented
    @test_skip crypticity(bcp)      # TODO: not yet implemented
end


@testset "Periodic process information measures" begin
    pp = periodic_process([0, 1, 1])

    @test_skip statistical_complexity(pp)
    @test_skip entropy_rate(pp)

    @test_skip excess_entropy(pp)  # TODO: not yet implemented
    @test_skip crypticity(pp)      # TODO: not yet implemented
end
