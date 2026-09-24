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
        em = new{T}(Set(alphabet), states, startstate, graph, exact_distribution)

        _is_unifilar(em) || throw(ArgumentError(
            "ε-Machine is not unifilar: each state should have one transition per symbol"))

        em
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
    str = "ε-Machine$(collect(em.alphabet))"
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

Base.getindex(em::EpsilonMachine, label) = em.graph[label]

#-------------------------------------------------------------------------------------------
transition_matrix(em::EpsilonMachine) = Float64.(Graphs.weights(em.graph))

function distribution(em::EpsilonMachine, exact=true)
    if exact == true && !isnothing(em.exact_distribution)
        return em.exact_distribution
    else
        # return em.inferred_distribution
        return nothing
    end
end

#-------------------------------------------------------------------------------------------

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


# Structural measures
num_states(em::EpsilonMachine) = length(em.states)

num_transitions(em::EpsilonMachine) = ne(em.graph)

alphabet_size(em::EpsilonMachine) = length(em.alphabet)

topological_complexity(em::EpsilonMachine) = log2(num_states(em))

# Core measures TODO
function statistical_complexity(em::EpsilonMachine)
    entropy(values(distribution(em)))
end

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

# excess_entropy(em::EpsilonMachine)

# crypticity(em::EpsilonMachine) = statistical_complexity(em) - excess_entropy(em)
