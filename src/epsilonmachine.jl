"""
    EpsilonMachine{T}

Represent an ε-machine as a unifilar automaton with a finite alphabet, a set of causal states,
and a transition graph.

# Fields
- `alphabet`: symbols accepted by the machine.
- `states`: causal states comprising the machine.
- `startstate`: label of the start state.
- `graph`: transition graph of the machine.
- `exact_distribution`: optional exact distribution over states.
"""
struct EpsilonMachine{T}
    alphabet::Vector{T}
    states::Vector{CausalState{T}}
    startstate::String
    graph::MetaGraph
    exact_distribution::Union{Dict{String,Probability},Nothing}
    # inferred_distribution::Union{Dict{String,Probability},Nothing}

    """
        EpsilonMachine(alphabet, states, startstate, exact_distribution=nothing)

    Construct an ε-machine from an alphabet, a vector of causal states, a start state label,
    and an optional exact distribution.

    Throws `ArgumentError` if the machine is not unifilar.
    """
    function EpsilonMachine(
        alphabet::AbstractVector{T},
        states::AbstractVector{<:CausalState{T}},
        startstate::AbstractString,
        exact_distribution=nothing
    ) where T
        # TODO validation
        alphabet = sort(unique(alphabet))
        graph = transition_graph(states)
        em = new{T}(alphabet, states, startstate, graph, exact_distribution)

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

    alphabet = collect(Iterators.flatten(symbols.(states)))
    EpsilonMachine(alphabet, states, startstate)
end

## Base extensions

function Base.show(io::IO, em::EpsilonMachine)
    str = "EpsilonMachine{$(eltype(em))}\n"
    str *="  alphabet: $(collect(em.alphabet))\n"
    str *="  states: $(num_states(em))\n"
    str *="  transitions: $(num_transitions(em))"
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

##
"""
    transition_matrix(em::EpsilonMachine)

Return the weighted transition matrix of the ε-machine graph.
"""
transition_matrix(em::EpsilonMachine) = Float64.(Graphs.weights(em.graph))

"""
    distribution(em::EpsilonMachine, exact=true)

Return the exact state distribution when available and `exact == true`.
Otherwise return the inferred_distribution (if it exists).

This is used to provide a machine-specific distribution when exact statistics are known.
"""
function distribution(em::EpsilonMachine, exact=true)
    if exact == true && !isnothing(em.exact_distribution)
        return em.exact_distribution
    else
        # return em.inferred_distribution
        return nothing
    end
end

"""
TODO: docstring
"""
simulate(em::EpsilonMachine, n::Int) = simulate(String, em, n)
simulate(::Type{String}, em::EpsilonMachine, n::Int) = join(Iterators.take(em, n))
simulate(::Type{Vector}, em::EpsilonMachine, n::Int) = collect(Iterators.take(em, n))


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

## Structural measures
"""
    num_states(em::EpsilonMachine)

Return the number of causal states in the ε-machine.
"""
num_states(em::EpsilonMachine) = length(em.states)

"""
    num_transitions(em::EpsilonMachine)

Return the number of transitions in the ε-machine graph.
"""
num_transitions(em::EpsilonMachine) = ne(em.graph)

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

## Core measures
"""
    statistical_complexity(em::EpsilonMachine)

Return the statistical complexity as the Shannon entropy of the state distribution.
"""
function statistical_complexity(em::EpsilonMachine)
    dist = distribution(em)
    entropy(collect(values(dist)))
end

"""
    entropy_rate(em::EpsilonMachine)

Estimate the entropy rate by averaging the per-state conditional entropies weighted by the
state distribution.
"""
function entropy_rate(em::EpsilonMachine)
    dist = distribution(em)
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

# TODO
# excess_entropy(em::EpsilonMachine)

# TODO
# crypticity(em::EpsilonMachine) = statistical_complexity(em) - excess_entropy(em)
