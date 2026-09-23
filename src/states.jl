struct Probability
    value::Float64

    function Probability(value::Real)
        0.0 <= value <= 1.0 || throw(ArgumentError("Probability must be in [0, 1], got $value"))
        new(Float64(value))
    end
end

Base.:(==)(p::Probability, q::Probability) = p.value == q.value
Base.isless(p::Probability, q::Probability) = isless(p.value, q.value)

Base.show(io::IO, p::Probability) = print(io, "P(", p.value, ")")
Base.Float64(p::Probability) = p.value

#-------------------------------------------------------------------------------------------
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

#-------------------------------------------------------------------------------------------
struct CausalState{T}
    label::String
    transitions::Vector{Transition{T}}

    # TODO validation
end

label(cs::CausalState) = cs.label
transitions(cs::CausalState) = cs.transitions
symbols(cs::CausalState) = symbol.(cs.transitions)
symboltype(::CausalState{T}) where T = T

#-------------------------------------------------------------------------------------------

function transition_graph(; name=nothing)
    return MetaGraph(
        DiGraph();
        label_type=String,
        vertex_data_type=CausalState,
        edge_data_type=Transition,
        graph_data=name,
        weight_function=t -> probability(t),
        default_weight=Probability(0),
    )
end

function transition_graph(states::AbstractVector{<:CausalState{T}}; name=nothing) where T
    graph = transition_graph(; name)

    for s in states
        graph[label(s)] = s
    end
    for s in states, t in transitions(s)
        graph[label(s), target(t)] = t
    end

    return graph
end
