# NOTE note used
#-------------------------------------------------------------------------------------------
#-------------------------------------------------------------------------------------------
"""
Suffix-array-backed replacement for `SuffixTree`, exposing the interface used by CSSR:

    SuffixTree{A}(; max_depth, alphabet)
    build_from_sequence!(tree, symbols; sa=nothing, lcp=nothing)
    get_stats(tree, history)      # -> HistoryStats or nothing
    histories(tree)               # iterator over all stored histories
    length(tree)                  # number of stored histories

Orientation
-----------
CSSR conditions on the *past*, so the index is built over the **reversed** sequence.
A history `h` (oldest → newest) is then a prefix of a suffix of the reversed string,
and the symbol that follows `h` in the original sequence is the character immediately
*before* the match in the reversed string.

Only prefixes up to `max_depth` are ever queried, so by default the suffix array is
sorted on truncated suffixes (O(n · max_depth · log n)). If you already have a full
suffix array / LCP array of the reversed sequence (1-based, `lcp[1] == 0`, symbols
ordered as `sort(alphabet)`), pass them via the `sa` and `lcp` keywords.
"""

"""Statistics for one history: occurrences that have a successor, and successor counts."""
struct HistoryStats{A}
    history::Vector{A}
    count::Int
    next_symbol_counts::Dict{A, Int}
end

mutable struct SuffixTree{A}
    max_depth::Int
    alphabet::Vector{A}
    code::Dict{A,Int}
    seq::Vector{A}          # sequence, encoded 1..σ
    sa::Vector{Int}         # suffix array of `rev`
    lcp::Vector{Int}        # lcp[i] = LCP(suffix sa[i-1], suffix sa[i]); lcp[1] = 0
    # prev::Matrix{A}         # prev[c, i+1] = #{ j ≤ i : rev[sa[j]-1] == c }
    histories::Vector{HistoryStats{A}}
end

# TODO CONTINUE FROM HERE
function SuffixTree(sequence::AbstractVector{A}; max_depth::Integer, alphabet::AbstractVector{A}) where A
    code = Dict{A,Int}(a => i for (i, a) in enumerate(alphabet))

    sequence_string = join(sequence)
    suffix_array = suffixsort(sequence_string)
    lcp_array = lcp(suffix_array, codeunits(sequence_string))

    # clip lcp array to max depth
    lcp_array = min.(lcp_array, max_depth)

    # create history stats for each unique history in the sequence (up to max depth)
    histories

    return SuffixTree{A}(
        max_depth,
        alphabet,
        code,
        sequence,
        suffix_array,
        lcp_array,
        # zeros(Int, length(alphabet), 1)
        histories
    )
end



    """
    history_stats(automaton::SuffixAutomaton{T}; max_depth) -> Dict{Vector{T}, Dict{T,Int}}

Get CSSR history statistics directly from a `SuffixAutomata.jl` `SuffixAutomaton`.

Each key is a history (oldest -> newest symbol); each value is a `Dict` of how
often each symbol followed it. `count` for a history is `sum(values(dist))`.

# How this works
`SuffixAutomaton` keeps the raw sequence in `automaton.data`, and its `transitions`
read left-to-right -- the same direction histories are read in (oldest -> newest) --
so no suffix-link walking, occurrence-count propagation, or clone detection is
needed (contrast building this from a bare SAM state table, which generally does
need those). For each start position, this just walks `transitions` forward one
symbol at a time, extending the history by one symbol per step and reading off
the actual next symbol from `data` directly.

Note: `root`, `.data`, and `.transitions` are plain struct fields rather than
part of the package's documented API (`occursin`, `findall`, `lcs`, `push!`,
...), so this relies on `SuffixAutomata.jl`'s current internals and could break
across package versions.
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
