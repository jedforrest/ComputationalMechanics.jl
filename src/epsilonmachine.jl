struct EpsilonMachine{T}
    alphabet::Set{T}
    states::Vector{CausalState{T}}
    startstate::String
    graph::MetaGraph
    exact_distribution::Union{Dict{String,Probability},Nothing}
    # inferred_distribution::Union{Dict{String,Probability},Nothing}

    function EpsilonMachine(
        alphabet::Union{AbstractSet{T},AbstractVector{T}},
        states::AbstractVector{<:CausalState{T}},
        startstate::AbstractString,
        exact_distribution=nothing
    ) where T
        # TODO validation

        graph = transition_graph(states)
        new{T}(Set(alphabet), states, startstate, graph, exact_distribution)
    end
end

# Constructor with only causal states
function EpsilonMachine(
    states::AbstractVector{<:CausalState{T}},
    startstate::AbstractString
) where T

    alphabet = Set(Iterators.flatten(symbols.(states)))
    EpsilonMachine(alphabet, states, startstate)
end


#-------------------------------------------------------------------------------------------

function Base.show(io::IO, em::EpsilonMachine)
    str = "EpsilonMachine$(collect(em.alphabet))"
    for s in em.states
        str *= "\n$s"
    end
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

#-------------------------------------------------------------------------------------------
transition_matrix(em::EpsilonMachine) = Float64.(Graphs.weights(em.graph))

# Structural measures
num_states(em::EpsilonMachine) = length(em.states)

num_transitions(em::EpsilonMachine) = ne(em.graph)

alphabet_size(em::EpsilonMachine) = length(em.alphabet)

topological_complexity(em::EpsilonMachine) = log2(num_states(em))


# Core measures TODO
statistical_complexity(em::EpsilonMachine)

entropy_rate(em::EpsilonMachine)

excess_entropy(em::EpsilonMachine)

crypticity(em::EpsilonMachine)


# TODO summary
print_summary(em::EpsilonMachine)
