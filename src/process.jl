## Common synthetic process machines

"""
    golden_mean_process(p=0.5)

Construct the golden-mean process with parameter `p`.

The process has two causal states and a binary alphabet.
"""
function golden_mean_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, p, "A"), Transition(1, 1 - p, "B")])
        CausalState("B", [Transition(0, 1, "A")])
    ]
    return EpsilonMachine([0, 1], states, "A")
end

"""
    even_process(p=0.5)

Construct the even process with parameter `p`.

The process alternates between states according to a binary-symbol rule.
"""
function even_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, p, "A"), Transition(1, 1 - p, "B")])
        CausalState("B", [Transition(1, 1, "A")])
    ]
    return EpsilonMachine([0, 1], states, "A")
end

"""
    biased_coin_process(p=0.5)

Construct a biased coin process with parameter `p`.

The machine emits a binary symbol while remaining in the same causal state.
"""
function biased_coin_process(p = 0.5)
    states = [
        CausalState("A", [Transition(0, 1 - p, "A"), Transition(1, p, "A")])
    ]
    return EpsilonMachine([0, 1], states, "A")
end

"""
    periodic_process(pattern=[0, 1])

Construct a periodic process whose symbols follow the given repeating pattern.

The resulting ε-machine uses one causal state for each symbol in `pattern`.
"""
function periodic_process(pattern::AbstractVector{T}=[0, 1]) where T
    n_states = length(pattern)
    states = CausalState{T}[]
    for (i, symbol) in enumerate(pattern)
        this_label = "σ$i"
        next_label = "σ$((i % n_states) + 1)"
        state = CausalState(this_label, [Transition(symbol, 1, next_label)])
        push!(states, state)
    end
    return EpsilonMachine(pattern, states, "σ1")
end
