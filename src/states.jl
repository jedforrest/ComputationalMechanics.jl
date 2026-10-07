## Transitions

"""
    Transition{T}

A state transition labeled by a symbol, a probability, and a target state.

# Fields
- `symbol`: emitted symbol associated with the transition.
- `probability`: probability of taking the transition.
- `target`: label of the destination state.
"""
struct Transition{T}
    symbol::T
    probability::Probability
    target::String

    function Transition(symbol::T, prob::Real, target) where T
        # TODO validation
        new{T}(symbol, Probability(prob), string(target))
    end
end

## Properties

"""
    symbol(t::Transition)

Return the emitted symbol associated with a transition.
"""
symbol(t::Transition) = t.symbol

"""
    probability(t::Transition)

Return the transition probability.
"""
probability(t::Transition) = t.probability

"""
    target(t::Transition)

Return the target state label for a transition.
"""
target(t::Transition) = t.target

"""
    symboltype(::Transition{T}) where {T}

Return the symbol type carried by a transition.
"""
symboltype(::Transition{T}) where T = T

## Base extensions
function Base.show(io::IO, t::Transition)
    print(io, "$(t.symbol)|$(t.probability) -> $(t.target)")
end

Base.eltype(::Type{Transition{T}}) where T = T
Base.eltype(::Transition{T}) where T = T

## Causal States

"""
    CausalState{T}

A causal state with a label and a collection of outgoing transitions.

# Fields
- `label`: state identifier.
- `transitions`: outgoing transitions from the state.
- `histories`: (optional) sequence histories that lead to this state
"""
struct CausalState{T}
    label::String
    transitions::Vector{Transition{T}}
    histories::Union{Vector{String},Nothing}

    function CausalState(
        label,
        transitions::AbstractVector{Transition{T}},
        histories=nothing
    ) where T
        # TODO validation
        total_prob = sum(tr.probability for tr in transitions)
        total_prob ≈ 1 || throw(ArgumentError("Total probability of transitions must sum to 1, got $total_prob"))

        new{T}(string(label), transitions, histories)
    end
end

## Properties

"""
    label(cs::CausalState)

Return the label of a causal state.
"""
label(cs::CausalState) = cs.label

"""
    transitions(cs::CausalState)

Return the outgoing transitions from a causal state.
"""
transitions(cs::CausalState) = cs.transitions

"""
    symbols(cs::CausalState)

Return the symbols emitted by the outgoing transitions of a state.
"""
symbols(cs::CausalState) = symbol.(cs.transitions)

"""
    symboltype(::CausalState{T}) where {T}

Return the symbol type used by a causal state.
"""
symboltype(::CausalState{T}) where T = T

"""
    histories(cs::CausalState)

History sequences that lead to this causal state. This may be determined by inference.
"""
histories(cs::CausalState) = cs.histories

"""
    valid_successors(cs::CausalState)

Return symbols with a non-zero probability of occuring next.
"""
valid_successors(cs::CausalState) = [tr.symbol for tr in cs if tr.probability > 0]

## Base extensions

function Base.show(io::IO, cs::CausalState)
    str = "State $(label(cs)): "
    for t in transitions(cs)
        str *= "\n  $t"
    end
    print(io, str)
end

Base.eltype(::Type{CausalState{T}}) where T = T
Base.eltype(::CausalState{T}) where T = T

Base.length(cs::CausalState) = length(cs.transitions)

# iterate over the outgoing transitions of a causal state
function Base.iterate(cs::CausalState, state=1)
    state > length(cs.transitions) && return nothing
    return (cs.transitions[state], state + 1)
end

## Transition graphs and traversal

"""
    transition_graph()

Construct an empty `MetaGraph` suitable for representing the transition graph of an ε-machine.
"""
function transition_graph()
    return MetaGraph(
        DiGraph();
        label_type=String,
        vertex_data_type=CausalState,
        edge_data_type=Transition,
        weight_function=t -> float(probability(t)),
        default_weight=0.,
    )
end

"""
    transition_graph(states::AbstractVector{<:CausalState{T}}) where {T}

Construct a transition graph from a collection of causal states.

Each state becomes a vertex and each transition becomes a directed edge with its probability
as the edge weight.
"""
function transition_graph(states::AbstractVector{<:CausalState{T}}) where T
    graph = transition_graph()

    for s in states
        graph[label(s)] = s
    end
    for s in states, t in transitions(s)
        graph[label(s), target(t)] = t
    end

    return graph
end


"""
    sample_next_transition(cs::CausalState)

Sample one outgoing transition from a causal state according to its transition probabilities.
"""
function sample_next_transition(cs::CausalState)
    trs = transitions(cs)
    W = Weights(float.(probability.(trs)))
    sample(trs, W)
end

"""
    emission_distribution(cs::CausalState{T}) where {T}

Return the distribution of emitted symbols from a causal state.
"""
function emission_distribution(cs::CausalState{T}; alphabet::AbstractVector{T}=symbols(cs)) where T
    trs = transitions(cs)
    Distribution(symbol.(trs), probability.(trs); alphabet)
end
