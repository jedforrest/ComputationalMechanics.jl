"""
    Probability(value::Real)

A probability value constrained to the interval [0, 1].

This is a lightweight real-valued wrapper used to keep probability constraints explicit
at construction time.
"""
struct Probability <: Real
    value::Float64

    function Probability(value::Real)
        0.0 <= value <= 1.0 || throw(ArgumentError("Probability must be in [0, 1], got $value"))
        new(Float64(value))
    end
end

## Base extensions

# Promotion
Base.convert(::Type{Probability}, p::Probability) = p
Base.convert(::Type{Probability}, x::Real) = Probability(x)
Base.convert(::Type{T}, p::Probability) where {T<:Real} = convert(T, p.value)
Base.promote_rule(::Type{Probability}, ::Type{<:Real}) = Float64

# Comparison
Base.:(==)(p::Probability, q::Probability) = p.value == q.value
Base.isless(p::Probability, q::Probability) = isless(p.value, q.value)

# Convenience
Base.Float64(p::Probability) = p.value
Base.float(p::Probability) = p.value

# Arithmetic
Base.:+(p::Probability, q::Probability) = Probability(p.value + q.value)
Base.:-(p::Probability, q::Probability) = Probability(p.value - q.value)
Base.:*(p::Probability, q::Probability) = Probability(p.value * q.value)
Base.:/(p::Probability, q::Probability) = Probability(p.value / q.value)

Base.isfinite(::Probability) = true

Base.show(io::IO, p::Probability) = print(io, "P($(round(p.value, digits=2)))")

## Entropy
"""
    entropy(p::Real)

Compute the binary entropy of a single probability `p`.
"""
entropy(p::Real) = -(p * log2(p))

"""
    entropy(ps::AbstractArray{<:Real})

Compute the Shannon entropy of a probability distribution represented by a vector of probabilities.
"""
entropy(ps::AbstractArray{<:Real}) = -sum(p * log2(p) for p in ps if p > 0)

## Distributions

const Distribution{T} = DefaultOrderedDict{T,Probability} where T

function Distribution(
    xs::AbstractVector{T},
    ps::AbstractVector{<:Real};
    alphabet::AbstractVector{T}=xs
) where T
    p_total = sum(ps)
    p_total ≈ 1 || throw(ArgumentError("Total probability must sum to 1, got $p_total"))
    dist = Distribution{T}(Probability(0), OrderedDict(xs .=> ps))
    for a in alphabet
        if !haskey(dist, a)
            dist[a] = 0
        end
    end
    return dist
end
