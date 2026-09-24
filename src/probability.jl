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
Base.float(p::Probability) = p.value

# Arithmetic
Base.:+(p::Probability, q::Probability) = Probability(p.value + q.value)
Base.:-(p::Probability, q::Probability) = Probability(p.value - q.value)
Base.:*(p::Probability, q::Probability) = Probability(p.value * q.value)
Base.:/(p::Probability, q::Probability) = Probability(p.value / q.value)

Base.show(io::IO, p::Probability) = print(io, "P($(p.value))")

#-------------------------------------------------------------------------------------------

entropy(p::Real) = -(p * log2(p))
entropy(ps::AbstractArray{<:Real}) = -sum(p * log2(p) for p in ps if p > 0)
