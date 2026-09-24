struct Transition{T}
    symbol::T
    probability::Probability
    target::String

    function Transition(symbol::T, prob::Real, target::AbstractString) where T
        # TODO validation
        new{T}(symbol, Probability(prob), target)
    end
end

symbol(t::Transition) = t.symbol
probability(t::Transition) = t.probability
target(t::Transition) = t.target
symboltype(::Transition{T}) where T = T

function Base.show(io::IO, t::Transition)
    print(io, "$(t.probability)|$(t.symbol) -> $(t.target)")
end

Base.eltype(::Type{Transition{T}}) where T = T
Base.eltype(::Transition{T}) where T = T

#-------------------------------------------------------------------------------------------
struct CausalState{T}
    label::String
    transitions::Vector{Transition{T}}

    function CausalState(
        label::AbstractString,
        transitions::AbstractVector{Transition{T}}
    ) where T
        # TODO validation
        total_prob = sum(tr.probability.value for tr in transitions)
        total_prob ≈ 1 || throw(ArgumentError("Total probability of transitions must sum to 1, got $total_prob"))

        new{T}(label, transitions)
    end
end

Base.eltype(::Type{CausalState{T}}) where T = T
Base.eltype(::CausalState{T}) where T = T

label(cs::CausalState) = cs.label
transitions(cs::CausalState) = cs.transitions
symbols(cs::CausalState) = symbol.(cs.transitions)
symboltype(::CausalState{T}) where T = T

function Base.show(io::IO, cs::CausalState)
    str = "State $(label(cs)):"
    for t in transitions(cs)
        str *= "\n  $t"
    end
    print(io, str)
end

# weighted sample of neighbour states based on transition probabilities
function sample_next_transition(cs::CausalState)
    trs = transitions(cs)
    W = Weights(Float64.(probability.(trs)))
    sample(trs, W)
end

function emission_distribution(cs::CausalState{T}) where T
    dist = Dict{T,Probability}()
    for t in transitions(cs)
        dist[t.symbol] = get(dist, t.symbol, 0.) + t.probability
    end
    return dist
end

#-------------------------------------------------------------------------------------------

function transition_graph()
    return MetaGraph(
        DiGraph();
        label_type=String,
        vertex_data_type=CausalState,
        edge_data_type=Transition,
        weight_function=t -> probability(t),
        default_weight=Probability(0),
    )
end

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
