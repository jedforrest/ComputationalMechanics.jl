struct EpsilonMachine{T}
    alphabet::Set{T}
    states::Vector{CausalState{T}}
    startstate::String
    graph::MetaGraph
    # stationary_distribution

    function EpsilonMachine(
        alphabet::Union{AbstractSet{T},AbstractVector{T}},
        states::AbstractVector{<:CausalState{T}},
        startstate::AbstractString
    ) where T
        # TODO validation

        graph = transition_graph(states)
        new{T}(Set(alphabet), states, startstate, graph)
    end
end

# Constructor with only causal states
function EpsilonMachine(
    states::AbstractVector{<:CausalState{T}},
    startstate::AbstractString
) where T
    println("outer constructor")
    alphabet = Set(Iterators.flatten(symbols.(states)))
    EpsilonMachine(alphabet, states, startstate)
end


#-------------------------------------------------------------------------------------------

function Base.iterate(s::MySequence, state = s.seed)
    next_state = # ... your logic to compute the next value from `state`
    value = # ... the value to emit this iteration
    return (value, next_state)
end

Base.IteratorSize(::Type{<:EpsilonMachine}) = Base.IsInfinite()
Base.eltype(::Type{EpsilonMachine{T}}) where T = T
Base.eltype(::EpsilonMachine{T}) where T = T
