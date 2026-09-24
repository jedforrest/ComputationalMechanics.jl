# Common synthetic process types

function golden_mean_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, p, "A"), Transition(1, 1 - p, "B")])
        CausalState("B", [Transition(0, 1, "A")])
    ]
    distribution = Dict(
        "A" => 1 / (2 - p),
        "B" => (1 - p) / (2 - p),
    )
    return EpsilonMachine([0, 1], states, "A", distribution)
end


function even_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, p, "A"), Transition(1, 1 - p, "B")])
        CausalState("B", [Transition(1, 1, "A")])
    ]
    distribution = Dict(
        "A" => 1 / (2 - p),
        "B" => (1 - p) / (2 - p),
    )
    return EpsilonMachine([0, 1], states, "A", distribution)
end


function biased_coin_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, 1 - p, "A"), Transition(1, p, "A")])
    ]
    distribution = Dict(
        "A" => 1,
    )
    return EpsilonMachine([0, 1], states, "A", distribution)
end


function periodic_process(pattern::AbstractVector{T}=[0, 1]) where T
    n_states = length(pattern)
    states = CausalState{T}[]
    for (i, symbol) in enumerate(pattern)
        this_label = "σ$i"
        next_label = "σ$((i % n_states) + 1)"
        state = CausalState(this_label, [Transition(symbol, 1, next_label)])
        push!(states, state)
    end
    distribution = Dict("σ$i" => 1/n_states for i in 1:n_states)
    return EpsilonMachine(pattern, states, "σ1", distribution)
end
