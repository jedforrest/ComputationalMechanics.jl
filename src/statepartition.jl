"""
    StatePartition

Bidirectional mapping between histories and the causal states CSSR assigns them
to, used by `_sufficiency_phase`, `_determinism_phase`, and `_build_machine`.
"""
mutable struct StatePartition{T}
    history_to_state::Dict{Vector{T},Int}
    state_to_histories::Dict{Int,Vector{Vector{T}}}
    next_id::Int
end

StatePartition{T}() where T = StatePartition{T}(Dict{Vector{T},Int}(), Dict{Int,Vector{Vector{T}}}(), 0)

"""
    new_state_id!(partition) -> Int

Reserve and return a fresh state id. The id has no histories until `assign!`
is called with it -- `state_ids(partition)` only reports states that currently
have at least one history, so an id from this call won't appear there until
then.
"""
function new_state_id!(partition::StatePartition)
    partition.next_id += 1
    return partition.next_id
end

"""
    assign!(partition, history, state_id)

Assign `history` to `state_id`, moving it out of any state it was previously
assigned to (removing that state entirely from `state_ids` if it's left with
no histories). Assigning a history to the state it's already in is a no-op.
"""
function assign!(partition::StatePartition{T}, history, state_id) where T
    old_state = get(partition.history_to_state, history, nothing)
    if old_state !== nothing
        old_state == state_id && return partition   # already there
        old_list = partition.state_to_histories[old_state]
        idx = findfirst(==(history), old_list)
        idx === nothing || deleteat!(old_list, idx)
        isempty(old_list) && delete!(partition.state_to_histories, old_state)
    end

    partition.history_to_state[history] = state_id
    new_list = get!(() -> Vector{T}[], partition.state_to_histories, state_id)
    push!(new_list, history)
    return partition
end

"""
    get_state(partition, history) -> state id or `nothing`

The state `history` is currently assigned to, or `nothing` if it hasn't been
assigned yet.
"""
get_state(partition::StatePartition, history) = get(partition.history_to_state, history, nothing)

"""
    get_histories(partition, state_id) -> Vector{Vector{T}}

All histories currently assigned to `state_id`, or an empty vector if the id
doesn't exist (e.g. it was merged away). Returns the partition's own internal
vector -- treat it as read-only; mutate via `assign!`/`merge_states!` instead.
"""
get_histories(partition::StatePartition{T}, state_id) where T =
    get(partition.state_to_histories, state_id, Vector{T}[])

"""
    state_ids(partition) -> Vector{Vector{T}}

Every state id that currently has at least one assigned history.
"""
state_ids(partition::StatePartition) = collect(keys(partition.state_to_histories))

"""
    merge_states!(partition, ids)

Merge every state in `ids` into `first(ids)`: all of their histories are
reassigned to that survivor, and the other ids are removed from `state_ids`.
No-op if `ids` has fewer than 2 elements.
"""
function merge_states!(partition::StatePartition{T}, ids::AbstractVector) where T
    length(ids) < 2 && return partition
    survivor = first(ids)
    survivor_list = get!(() -> Vector{T}[], partition.state_to_histories, survivor)

    for id in ids[2:end]
        id == survivor && continue
        histories = get(partition.state_to_histories, id, Vector{T}[])
        for h in histories
            partition.history_to_state[h] = survivor
        end
        append!(survivor_list, histories)
        delete!(partition.state_to_histories, id)
    end
    return partition
end

"""
    copy(partition::StatePartition) -> StatePartition

An independent copy: mutating the result (via `assign!`/`merge_states!`) never
affects the original. Used by `_determinism_phase` to iteratively merge states
without disturbing the partition `_sufficiency_phase` produced.
"""
function Base.copy(partition::StatePartition{T}) where T
    return StatePartition(
        copy(partition.history_to_state),
        Dict{Int,Vector{Vector{T}}}(k => copy(v) for (k, v) in partition.state_to_histories),
        partition.next_id,
    )
end

function Base.show(io::IO, partition::StatePartition)
    n = length(partition.state_to_histories)
    m = length(partition.history_to_state)
    print(io, "StatePartition($n states, $m histories)")
end
