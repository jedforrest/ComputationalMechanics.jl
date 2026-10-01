# This is based on emics implementation of CSSR
abstract type InferenceAlgorithm end

struct CSSR <: InferenceAlgorithm end

struct InferenceResult{T}
    machine::EpsilonMachine{T}
    histories::Dict{String, Dict{T, Int}}
    sequence_length::Int
    max_history::Int
    automaton::SuffixAutomaton{T}
    alg::InferenceAlgorithm
end

"""
    infer_machine(alg::CSSR, sequence; alphabet=nothing)

Infer an ε-machine from `sequence`. If `alphabet` is not given it is taken to be
the set of symbols observed in `sequence`.
"""
function infer_machine(
    ::CSSR,
    sequence;
    alphabet=sort(unique(sequence)),
    max_history = 6,
    alpha = 0.05,
    min_count = 5,
    statistical_test = :chi2,  # chi2 | ks | g
    # max_iteratons = 1000,
    # post_merge = true,
    # merge_significance = 0.05
)
    # validate parameters
    max_history >= 1 || throw(ArgumentError("max_history must be >= 1"))
    min_count >= 1 || throw(ArgumentError("min_count must be >= 1"))
    0 < alpha <= 1 || throw(ArgumentError("alpha must be between 0 and 1"))
    statistical_test in [:chi2, :ks, :g] || throw(ArgumentError(
        "$statistical_test is not a valid statistical test. Choose from :chi2, :ks, or :g."))

    n_syms = length(sequence)
    min_required = min_count * (max_history + 1) * 2
    n_syms < min_required && throw(ArgumentError(
            "Provided sequence has $n_syms symbols,"*
            "but $min_required are required for the CSSR algorithm."
        )
    )

    # Phase I: build suffix automaton on the sequence
    automaton = SuffixAutomaton(sequence)
    history = history_stats(automaton; max_depth=max_history)

    # Phase II: level-by-level sufficiency testing
    # TODO CONTINUE FROM HERE
    partition = _sufficiency_phase(history, alphabet, min_count)

    return partition
    # # Phase III: ensure determinism (merge equivalent states)
    # partition = _determinism_phase(cfg, partition, tree)

    # machine = _build_machine(cfg, partition, tree, alph)

    # return InferenceResult(
    #     machine,
    #     history,
    #     n_syms,
    #     max_history,
    #     automaton,
    #     CSSR(),
    # )
end

# ------------------------------------------------------------------------------
# Phase I: histories
# ------------------------------------------------------------------------------

    """
    history_stats(automaton::SuffixAutomaton{T}; max_depth) -> Dict{Vector{T}, Dict{T,Int}}

Get CSSR history statistics directly from a `SuffixAutomata.jl` `SuffixAutomaton`.

Each key is a history (oldest -> newest symbol); each value is a `Dict` of how
often each symbol followed it. `count` for a history is `sum(values(dist))`.
"""
function history_stats(automaton::SuffixAutomaton{T}; max_depth::Integer=5) where {T}
    data = automaton.data
    n = length(data)
    stats = Dict{String,Dict{T,Int}}()

    for j in 1:n
        current = automaton.root
        for len in 1:min(max_depth, n - j)      # stop one short of the end: a next symbol must exist
            symbol = data[j + len - 1]
            current = current.transitions[symbol]
            h = join(data[j:(j + len - 1)])
            nxt = data[j + len]
            dist = get!(Dict{T,Int}, stats, h)
            dist[nxt] = get(dist, nxt, 0) + 1
        end
    end

    # Empty history: the overall symbol distribution.
    empty_dist = Dict{T,Int}()
    for s in data
        empty_dist[s] = get(empty_dist, s, 0) + 1
    end
    stats[""] = empty_dist

    return stats
end

# ------------------------------------------------------------------------------
# Phase II: sufficiency
# ------------------------------------------------------------------------------


# """
#     _lookup(stats, automaton, h; max_depth) -> (count, next_symbol_counts) or nothing

# `next_symbol_counts` is the `Dict` of how often each symbol followed `h`; `count`
# is `sum(values(next_symbol_counts))`. Returns `nothing` if `h` never occurred
# with a successor.
# """
# function _lookup(
#     stats::Dict{String, Dict{A, Int}},
#     h::AbstractVector{A};
# ) where A
#     dist = get(stats, h, nothing)
#     dist === nothing && return nothing
#     return sum(values(dist); init = 0), dist
# end

# ------------------------------------------------------------------------------
# Phase II: sufficiency
# ------------------------------------------------------------------------------
include("statepartition.jl")

"""
    _sufficiency_phase(cfg, stats, automaton, alphabet)

`stats` is the output of `history_stats(automaton; max_depth = cfg.max_history)`.
`automaton` may be `nothing` if you're confident no history will ever need a
deeper lookup than `cfg.max_history` (e.g. `cfg.max_history` is small relative
to how much data you have) -- otherwise pass the automaton it came from.
"""
function _sufficiency_phase(hist_stats::Dict{String, Dict{T, Int}}, alphabet, min_count) where T
    partition = StatePartition()

    all_histories = String[]
    sync_histories = String[]
    nonsync_histories = String[]

    # hist_stats is a dict of histories to next-value distributions
    for (hist, dist) in hist_stats
        isempty(hist) && continue
        count = sum(values(dist); init = 0)
        count < min_count && continue

        push!(all_histories, hist)
        if _is_synchronizing(hist, hist_stats; alphabet, min_count)
            push!(sync_histories, hist)
        else
            push!(nonsync_histories, hist)
        end
    end

    # partition ids
    if isempty(all_histories)
        state_id = new_state_id!(partition)
        for a in alphabet
            assign!(partition, [a], state_id)
        end
        return partition
    end

    # If no synchronizing histories exist, fall back to using all of them
    if isempty(sync_histories)
        sync_histories = all_histories
        nonsync_histories = empty(all_histories)
    end

    # Group synchronizing histories by distribution
    _group_by_distribution!(partition, sync_histories, hist_stats, min_count)

    # # Assign non-synchronizing histories to state of their sync suffix
    # TODO CONTINUE FROM HERE
    # for h in nonsync_histories
    #     state = _find_state_for_history(cfg, h, partition, hist_stats, automaton)
    #     state === nothing || assign!(partition, h, state)
    # end

    return partition
end

"""
A history is synchronizing if all its parent extensions have consistent
distributions. Ambiguity propagates: if the length-(L-1) suffix is
non-synchronizing, so is the history.
"""
function _is_synchronizing(history, history_stats; alphabet, min_count)
    if length(history) > 1
        suffix = history[2:end]  # Remove first element
        !_is_synchronizing_core(suffix, history_stats; alphabet, min_count) && return false
    end
    return _is_synchronizing_core(history, history_stats; alphabet, min_count)
end

"""
Core synchronizing check: compare the distributions of the one-symbol-longer
extensions of `history` (prepended at the front, i.e. one step further into the
past).
"""
function _is_synchronizing_core(history, history_stats; alphabet, min_count)
    h_stats = get(history_stats, history, nothing)
    h_stats === nothing && return false

    # Check extensions: (a,) + history for each a in alphabet
    extension_dists = Dict{eltype(history),Int}[]
    for a in alphabet
        extended = a * history  # prepend
        ext_dist = get(history_stats, extended, nothing)

        isnothing(ext_dist) && continue
        count = sum(values(ext_dist); init = 0)
        count < min_count && continue
        push!(extension_dists, ext_dist)
    end

    # Too few extensions to compare (e.g. max-depth histories with sparse data)
    length(extension_dists) < 2 && return true

    for i in 1:(length(extension_dists) - 1)
        for j in (i + 1):length(extension_dists)
            if distributions_differ(extension_dists[i], extension_dists[j])
                return false
            end
        end
    end
    return true
end


function distributions_differ(dist1::Dict{A,<:Integer}, dist2::Dict{A,<:Integer};
        alpha::Real=0.001, statistical_test=:chi2) where A
    # TODO could have multiple tests to choose from here
    if statistical_test == :chi2
        return chisq_differ(dist1, dist2, alpha)
    # elseif statistical_test == :p
    #     return proportion_differ(dist1, dist2, alpha)
    else
        throw(ArgumentError("$statistical_test is not a valid statistical test."))
    end
end


function chisq_differ(dist1::Dict{A,<:Integer}, dist2::Dict{A,<:Integer}, alpha::Real) where A
    n1 = sum(values(dist1); init = 0)
    n2 = sum(values(dist2); init = 0)
    (n1 == 0 || n2 == 0) && return false

    symbols = collect(union(keys(dist1), keys(dist2)))
    k = length(symbols)
    k < 2 && return false   # only one possible outcome -- nothing to compare

    table = Matrix{Int}(undef, 2, k)
    for (j, s) in enumerate(symbols)
        table[1, j] = get(dist1, s, 0)
        table[2, j] = get(dist2, s, 0)
    end

    # TODO worth including this warning?
    grand_total = n1 + n2
    n_low_expected = count(Iterators.product(1:2, 1:k)) do (i, j)
        row_total = i == 1 ? n1 : n2
        col_total = table[1, j] + table[2, j]
        (row_total * col_total / grand_total) < 5
    end
    if n_low_expected / (2k) > 0.2
        @warn "chisq_differ: >20% of cells have expected count < 5; " *
              "the chi-squared approximation may be unreliable" n1 n2 k
    end

    return pvalue(ChisqTest(table)) < alpha
end


# function proportion_differ(dist1::Dict{A,<:Integer}, dist2::Dict{A,<:Integer}, tolerance::Real) where A
#     total1 = sum(values(dist1))
#     total2 = sum(values(dist2))

#     if total1 < 5 || total2 < 5
#         return false
#     end

#     all_keys = unique([keys(dist1); keys(dist2)])

#     for key in all_keys
#         p1 = get(dist1, key, 0) / total1
#         p2 = get(dist2, key, 0) / total2
#         if abs(p1 - p2) > tolerance
#             return true
#         end
#     end
#     return false
# end


"""Find a state for a non-synchronizing history, or `nothing` if none matches."""
function _find_state_for_history(cfg::CSSRConfig, history, partition, stats, automaton)
    # Longest proper suffix already assigned to a state
    for i in 2:length(history)
        state = get_state(partition, history[i:end])
        state === nothing || return state
    end

    # Fall back to distribution matching
    result = _lookup(stats, automaton, history; max_depth = cfg.max_history)
    result === nothing && return nothing
    _, dist = result

    for state_id in state_ids(partition)
        state_dist = _state_distribution(state_id, partition, stats, automaton; max_depth = cfg.max_history)
        if !distributions_differ(dist, state_dist, cfg.significance, cfg.test)
            return state_id
        end
    end
    return nothing
end

"""
Group histories by distribution similarity, mutating `partition`.

1. If all histories are mutually homogeneous, put them in a single state.
2. Otherwise, greedily group against a representative distribution per group.
"""
function _group_by_distribution!(
    partition::StatePartition,
    hists::AbstractVector{<:AbstractString},
    hist_stats::Dict{String, Dict{A, Int}},
    min_count::Int
) where A
    isempty(hists) && return partition

    entries = @NamedTuple{history::String, counts::Dict{A,Int}}[]
    for h in hists
        dist = hist_stats[h]
        count = sum(values(dist); init = 0)
        count < min_count && continue
        push!(entries, (; history = h, counts = copy(dist)))
    end
    isempty(entries) && return partition

    # Pairwise test of consecutive histories with a lenient threshold; more robust
    # than testing against a large pooled distribution.
    homog_sig = 0.01
    all_homogeneous = all(1:min(length(entries) - 1, 10)) do i
        !distributions_differ(entries[i].counts, entries[i + 1].counts; alpha=homog_sig)
    end

    # Also reject if any symbol's proportion varies too much across histories
    if all_homogeneous
        all_keys = Set{A}()
        for e in entries
            union!(all_keys, keys(e.counts))
        end

        min_props = Dict{A,Float64}()
        max_props = Dict{A,Float64}()
        for e in entries
            total = sum(values(e.counts))
            total < 1 && continue
            for k in all_keys
                p = get(e.counts, k, 0) / total
                min_props[k] = min(get(min_props, k, 1.0), p)
                max_props[k] = max(get(max_props, k, 0.0), p)
            end
        end

        tolerance = 0.25  # allowed range for sampling variability
        all_homogeneous = all(all_keys) do k
            get(max_props, k, 0.0) - get(min_props, k, 0.0) <= tolerance
        end
    end

    if all_homogeneous
        state_id = new_state_id!(partition)
        for e in entries
            assign!(partition, e.history, state_id)
        end
        return partition
    end

    # Greedy grouping with a lenient threshold
    group_sig = 0.1
    groups = [[entries[1].history]]
    group_reps = [copy(entries[1].counts)]

    for e in @view entries[2:end]
        i = findfirst(group_reps) do rep
            !distributions_differ(e.counts, rep; alpha= group_sig)
        end
        if i === nothing
            push!(groups, [e.history])
            push!(group_reps, copy(e.counts))
        else
            push!(groups[i], e.history)
        end
    end

    for group in groups
        state_id = new_state_id!(partition)
        for h in group
            assign!(partition, h, state_id)
        end
    end
    return partition
end

# ------------------------------------------------------------------------------
# Shared helper (also used by Phase III / machine construction, if you carry
# the same (stats, automaton) swap through there)
# ------------------------------------------------------------------------------

"""Aggregate next-symbol counts over all histories assigned to `state_id`."""
function _state_distribution(
    state_id,
    partition,
    stats::HistoryStats{A},
    automaton;
    max_depth::Integer,
) where {A}
    aggregate = Dict{A,Int}()
    for h in get_histories(partition, state_id)
        result = _lookup(stats, automaton, h; max_depth)
        result === nothing && continue
        _, dist = result
        mergewith!(+, aggregate, dist)
    end
    return aggregate
end

_prepend(a, history) = pushfirst!(copy(history), a)

#=
Call site in `infer` (cssr.jl) changes from:

    tree = SuffixTree{A}(; max_depth = cfg.max_history, alphabet = alph)
    build_from_sequence!(tree, symbols)
    partition = _sufficiency_phase(cfg, tree, alph)

to something like:

    automaton = SuffixAutomaton(symbols)
    stats = history_stats(automaton; max_depth = cfg.max_history)
    partition = _sufficiency_phase(cfg, stats, automaton, alph)

Phase III (`_determinism_phase`, `_build_machine`) still call the old
`_state_distribution(state_id, partition, tree)` / `get_stats(tree, h)` and
would need the same (stats, automaton; max_depth) swap to stay consistent --
not changed here since only the sufficiency phase was in scope.
=#

# ------------------------------------------------------------------------------
# Phase III: determinism
# ------------------------------------------------------------------------------

"""
Merge states whose aggregate next-symbol distributions are indistinguishable,
until no mergeable pair remains. Uses a lenient merge threshold (≥ 0.1) to avoid
over-splitting. Returns a new partition; the input is left unchanged.
"""
function _determinism_phase(cfg::CSSRConfig, partition::StatePartition, tree)
    current = copy(partition)
    merge_sig = max(something(cfg.merge_significance, cfg.significance), 0.1)

    while true
        pair = _find_mergeable_pair(cfg, current, tree, merge_sig)
        pair === nothing && break
        merge_states!(current, collect(pair))
    end
    return current
end

"""Return the first pair of states with indistinguishable distributions, or `nothing`."""
function _find_mergeable_pair(cfg::CSSRConfig, partition, tree, significance)
    ids = state_ids(partition)
    for i in 1:(length(ids) - 1)
        dist1 = _state_distribution(ids[i], partition, tree)
        for j in (i + 1):length(ids)
            dist2 = _state_distribution(ids[j], partition, tree)
            distributions_differ(dist1, dist2, significance, cfg.test) ||
                return (ids[i], ids[j])
        end
    end
    return nothing
end

# ------------------------------------------------------------------------------
# Machine construction
# ------------------------------------------------------------------------------

"""Construct an ε-machine from a state partition."""
function _build_machine(cfg::CSSRConfig, partition, tree::SuffixTree{A}, alphabet) where {A}
    builder = EpsilonMachineBuilder{A}()

    ids = state_ids(partition)
    if isempty(ids)
        ids = ["S0"]
        assign!(partition, A[], "S0")
    end

    for state_id in ids
        hists = get_histories(partition, state_id)
        symbol_counts = _state_distribution(state_id, partition, tree)

        total = sum(values(symbol_counts))
        if total == 0
            total = length(alphabet)
            symbol_counts = Dict{A,Int}(a => 1 for a in alphabet)
        end

        for (sym, cnt) in symbol_counts
            target = something(_find_target_state(cfg, hists, sym, partition), state_id)
            add_transition!(
                builder;
                source = state_id,
                symbol = sym,
                target,
                probability = cnt / total,
            )
        end
    end

    with_start_state!(builder, first(ids))
    return build(builder)
end

"""Find the state reached after emitting `symbol` from any of `hists`, or `nothing`."""
function _find_target_state(cfg::CSSRConfig, hists, symbol, partition)
    for h in hists
        extended = length(h) >= cfg.max_history ? push!(h[2:end], symbol) : push!(copy(h), symbol)

        target = get_state(partition, extended)
        target === nothing || return target

        # Try progressively shorter suffixes
        for i in 2:length(extended)
            target = get_state(partition, extended[i:end])
            target === nothing || return target
        end
    end
    return nothing
end

# ------------------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------------------

"""Aggregate next-symbol counts over all histories assigned to `state_id`."""
function _state_distribution(state_id, partition, tree::SuffixTree{A}) where {A}
    aggregate = Dict{A,Int}()
    for h in get_histories(partition, state_id)
        stats = get_stats(tree, h)
        stats === nothing || mergewith!(+, aggregate, stats.next_symbol_counts)
    end
    return aggregate
end

_prepend(a, history) = pushfirst!(copy(history), a)
