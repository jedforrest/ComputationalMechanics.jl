## Common synthetic process machines

"""
    golden_mean_process(p=0.5)

Construct the golden-mean process with parameter `p`.

The process has two causal states and a binary alphabet.
"""
function golden_mean_process(p = 0.5)
    states = [
        CausalState("A", [Transition('0', p, "A"), Transition('1', 1 - p, "B")], ["0"])
        CausalState("B", [Transition('0', 1, "A")], ["1"])
    ]
    return EpsilonMachine(['0', '1'], states, "A")
end

"""
    even_process(p=0.5)

Construct the even process with parameter `p`.

The process alternates between states according to a binary-symbol rule.
"""
function even_process(p = 0.5)
    states = [
        CausalState("A", [Transition('0', p, "A"), Transition('1', 1 - p, "B")], ["0"])
        CausalState("B", [Transition('1', 1, "A")], ["1"])
    ]
    return EpsilonMachine(['0', '1'], states, "A")
end

"""
    biased_coin_process(p=0.5)

Construct a biased coin process with parameter `p`.

The machine emits a binary symbol while remaining in the same causal state.
"""
function biased_coin_process(p = 0.5)
    states = [
        CausalState("A", [Transition('0', 1 - p, "A"), Transition('1', p, "A")], ["0", "1"])
    ]
    return EpsilonMachine(['0', '1'], states, "A")
end

"""
    periodic_process(pattern=[0, 1])

Construct a periodic process whose symbols follow the given repeating pattern.

The resulting ε-machine uses one causal state for each symbol in `pattern`.
"""
function periodic_process(pattern::AbstractVector{T}=['0', '1']) where T
    n_states = length(pattern)
    states = CausalState{T}[]
    for (i, symbol) in enumerate(pattern)
        this_label = "σ$i"
        next_label = "σ$((i % n_states) + 1)"
        prev_symbol = i == 1 ? pattern[end] : pattern[i - 1]
        state = CausalState(this_label, [Transition(symbol, 1, next_label)], [string(prev_symbol)])
        push!(states, state)
    end
    return EpsilonMachine(pattern, states, "σ1")
end


"""
    feldman_hanna_process()

A seven-state process used to study human sequence prediction.

Reference: Feldman, J., & Hanna, J. F. (1966).
"""
function feldman_hanna_process()
    states = [
        CausalState("AAA", [Transition('A', 3/16, "AAA"), Transition('B', 13/16, "AAAB")], ["AAA"])
        CausalState("AAAB", [Transition('A', 3/16, "BA"), Transition('B', 13/16, "BB")], ["AAAB"])
        CausalState("BA", [Transition('A', 9/16, "BAA"), Transition('B', 7/16, "BAB")], ["BA"])
        CausalState("BB", [Transition('A', 15/16, "BA"), Transition('B', 1/16, "BB")], ["BB"])
        CausalState("BAA", [Transition('A', 9/16, "AAA"), Transition('B', 7/16, "BAAB")], ["BAA"])
        CausalState("BAB", [Transition('A', 4/16, "BA"), Transition('B', 12/16, "BB")], ["BAB"])
        CausalState("BAAB", [Transition('A', 12/16, "BA"), Transition('B', 4/16, "BB")], ["BAAB"])
    ]
    return EpsilonMachine(['A', 'B'], states)
end
