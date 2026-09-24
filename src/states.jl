struct Probability <: Real
    value::Float64

    function Probability(value::Real)
        0.0 <= value <= 1.0 || throw(ArgumentError("Probability must be in [0, 1], got $value"))
        new(Float64(value))
    end
end

# Promotion
Base.convert(::Type{Probability}, x::Real) = Probability(x)
Base.convert(::Type{T}, p::Probability) where {T<:Real} = convert(T, p.value)
Base.promote_rule(::Type{Probability}, ::Type{<:Real}) = Float64

# Comparison
Base.:(==)(p::Probability, q::Probability) = p.value == q.value
Base.isless(p::Probability, q::Probability) = isless(p.value, q.value)

# Convenience
Base.Float64(p::Probability) = p.value

# Arithmetic
Base.:+(p::Probability, q::Probability) = Probability(p.value + q.value)
Base.:-(p::Probability, q::Probability) = Probability(p.value - q.value)
Base.:*(p::Probability, q::Probability) = Probability(p.value * q.value)
Base.:/(p::Probability, q::Probability) = Probability(p.value / q.value)

Base.show(io::IO, p::Probability) = print(io, "P(", p.value, ")")

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

function Base.show(io::IO, t::Transition)
    print(io, "$(t.probability)|$(t.symbol) -> $(t.target)")
end

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
