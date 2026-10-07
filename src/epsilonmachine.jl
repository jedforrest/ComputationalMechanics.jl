"""
    EpsilonMachine{T}

Represent an ε-machine as a unifilar automaton with a finite alphabet, a set of causal states,
and a transition graph.

# Fields
- `alphabet`: symbols accepted by the machine.
- `states`: causal states comprising the machine.
- `startstate`: label of the start state.
- `graph`: transition graph of the machine.
"""
mutable struct EpsilonMachine{T}
    alphabet::Vector{T}
    states::Vector{CausalState{T}}
    startstate::String
    graph::MetaGraph

    """
        EpsilonMachine(alphabet, states, startstate)

    Construct an ε-machine from an alphabet, a vector of causal states, and optional
    starting state.

    Throws `ArgumentError` if the machine is not unifilar.
    """
    function EpsilonMachine(
        alphabet::AbstractVector{T},
        states::AbstractVector{<:CausalState{T}},
        startstate::AbstractString=first(label.(states))
    ) where T
        # TODO validation
        alphabet = sort(unique(alphabet))
        graph = transition_graph(states)
        em = new{T}(alphabet, states, startstate, graph)

        _is_unifilar(em) || throw(ArgumentError(
            "ε-Machine is not unifilar: each state should have one transition per symbol"))

        em
    end
end

## Constructors

"""
    EpsilonMachine(states, startstate)

Construct an ε-machine from causal states by inferring the alphabet from the emitted symbols.
"""
function EpsilonMachine(
    states::AbstractVector{<:CausalState{T}},
    startstate::AbstractString
) where T

    alphabet = sort(collect(Iterators.flatten(symbols.(states))))
    EpsilonMachine(alphabet, states, startstate)
end

## Base extensions

function Base.show(io::IO, em::EpsilonMachine)
    str = "EpsilonMachine{$(eltype(em))}\n"
    str *= "  alphabet: $(collect(em.alphabet))\n"
    str *= "  states: $(num_states(em))\n"
    str *= "  transitions: $(num_transitions(em))"
    print(io, str)
end

function Base.iterate(em::EpsilonMachine, state=em.startstate)
    this_state = em.graph[state]
    trans = sample_next_transition(this_state)
    next_state = trans.target
    value = trans.symbol
    return (value, next_state)
end

Base.IteratorSize(::Type{<:EpsilonMachine}) = Base.IsInfinite()

Base.eltype(::Type{EpsilonMachine{T}}) where T = T
Base.eltype(::EpsilonMachine{T}) where T = T

Base.getindex(em::EpsilonMachine, label) = em.graph[label]

Base.:(==)(em1::EpsilonMachine, em2::EpsilonMachine) = isequal(em1.alphabet, em2.alphabet) &&
    isequal(em1.startstate, em2.startstate) &&
    isequal(em1.states, em2.states)

## Core properties and functions

states(em::EpsilonMachine) = em.states

transitions(em::EpsilonMachine) = collect(Iterators.flatten(transitions.(em.states)))

labels(em::EpsilonMachine) = label.(em.states)

function histories(em::EpsilonMachine)
    history = Dict{String, Int}()
    for (i, s) in enumerate(states(em))
        state_hist = histories(s)
        isnothing(state_hist) && continue
        for h in state_hist
            history[h] = i
        end
    end
    return isempty(history) ? nothing : history
end

"""
    transition_matrix(em::EpsilonMachine)

Return the weighted transition matrix of the ε-machine graph.
"""
transition_matrix(em::EpsilonMachine) = float.(Graphs.weights(em.graph))


"""
    stationary_distribution(em::EpsilonMachine)

Calculate the stationary distribution from the ε-machine graph.
"""
function stationary_distribution(em::EpsilonMachine)
    # get eigenvalue decomposition of transition matrix and normalise
    P = transition_matrix(em)
    vals, vecs = eigen(P')
    ps = real(vecs[:, argmin(abs.(vals .- 1))])
    ps ./= sum(ps)
    return Distribution(label.(em.states), ps)
end


"""
    simulate(em::EpsilonMachine, n::Int)

Simulate the ε-machine for `n` steps, returning a string of emitted symbols.
"""
simulate(em::EpsilonMachine, n::Int) = simulate(String, em, n)
simulate(::Type{String}, em::EpsilonMachine, n::Int) = join(Iterators.take(em, n))
simulate(::Type{Vector}, em::EpsilonMachine, n::Int) = collect(Iterators.take(em, n))


function predict(em::EpsilonMachine, history::AbstractString)
    # check if alphabets are compatible
    Set(unique(history)) <= Set(em.alphabet) || error("ε-machine's alphabet cannot produce this history sequence")

    history_to_state = histories(em)
    isnothing(history_to_state) && error("ε-machine has no recorded state histories.")

    state_idx = match_history_to_state(history_to_state, history)
    isnothing(state_idx) && error("No valid state found")

    emission_distribution(em.states[state_idx])
end


function filter_states(em::EpsilonMachine, history::AbstractString)
    # check if alphabets are compatible
    Set(unique(history)) <= Set(em.alphabet) || error("ε-machine's alphabet cannot produce this history sequence")

    history_to_state = histories(em)
    isnothing(history_to_state) && error("ε-machine has no recorded state histories.")

    # get the best-matched state for a growing history list
    N = length(history)
    state_labels = String[]
    for n in 1:N
        hist = history[1:n]
        state_idx = match_history_to_state(history_to_state, hist)
        isnothing(state_idx) && continue
        state = em.states[state_idx]

        # check that the next symbol in the sequence is reachable
        if n < N && !(history[n + 1] in valid_successors(state))
            error("The subsequence '$(history[1:n+1])' is not possible for this ε-machine.")
        end

        push!(state_labels, state.label)
    end
    return state_labels
end


function match_history_to_state(history_to_state::Dict{String, Int}, history::AbstractString)
    # find the best state_index match for the given history sequence
    # reduce the suffix until a match is found (otherwise return nothing)
    max_hist_length = maximum(length, keys(history_to_state))  # max_history
    n = min(length(history), max_hist_length)

    hist = history[end-n+1:end]
    state_idx = nothing
    while n > 0
        hist = history[end-n+1:end]
        state_idx = get(history_to_state, hist, nothing)
        !isnothing(state_idx) && break
        n -= 1
    end
    return state_idx
end



## Validation

"""
    _is_unifilar(em::EpsilonMachine)

Check whether each causal state has at most one outgoing transition for each emitted symbol.

Returns `true` if the machine is unifilar and `false` otherwise.
"""
function _is_unifilar(em::EpsilonMachine)
    for state in em.states
        seen = []
        for sym in symbols(state)
            sym in seen && return false
            push!(seen, sym)
        end
    end
    return true
end

## Structural and statistical measures
"""
    num_states(em::EpsilonMachine)

Return the number of causal states in the ε-machine.
"""
num_states(em::EpsilonMachine) = length(states(em))

"""
    num_transitions(em::EpsilonMachine)

Return the number of transitions in the ε-machine graph.
"""
num_transitions(em::EpsilonMachine) = length(transitions(em))

"""
    alphabet_size(em::EpsilonMachine)

Return the size of the machine alphabet.
"""
alphabet_size(em::EpsilonMachine) = length(em.alphabet)

"""
    topological_complexity(em::EpsilonMachine)

Return the topological complexity of the machine, defined as the base-2 logarithm of the
number of states.
"""
topological_complexity(em::EpsilonMachine) = log2(num_states(em))


"""
    statistical_complexity(em::EpsilonMachine)

Return the statistical complexity as the Shannon entropy of the state distribution.
"""
function statistical_complexity(em::EpsilonMachine)
    dist = stationary_distribution(em)
    entropy(collect(values(dist)))
end

"""
    entropy_rate(em::EpsilonMachine)

Estimate the entropy rate by averaging the per-state conditional entropies weighted by the
state distribution.
"""
function entropy_rate(em::EpsilonMachine)
    dist = stationary_distribution(em)
    h = 0.

    for state in em.states
        state_p = get(dist, state.label, 0.)
        state_p <= 0. && continue

        state_dist = emission_distribution(state)
        state_h = 0.
        for prob in values(state_dist)
            if prob > 0
                state_h += entropy(prob)
            end
        end
        h += state_p * state_h
    end

    return h
end
