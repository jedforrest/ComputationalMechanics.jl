module ComputationalMechanics

using Random
using StatsBase
using Graphs, MetaGraphsNext

include("probability.jl")
export Probability

include("states.jl")
export Transition, CausalState, transition_graph, sample_next_transition, emission_distribution
export label, transitions, symbols, symboltype, probability

include("epsilonmachine.jl")
export EpsilonMachine, transition_matrix, distribution, alphabet_size, topological_complexity
export num_states, num_transitions, statistical_complexity, entropy_rate

include("process.jl")
export golden_mean_process, even_process, biased_coin_process, periodic_process

end
