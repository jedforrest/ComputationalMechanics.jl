module ComputationalMechanics

using Random
using StatsBase
using Graphs, MetaGraphsNext, PlotGraphviz
using SuffixAutomata
using HypothesisTests: ChisqTest, pvalue
using LinearAlgebra: eigen

include("probability.jl")
export Probability

include("states.jl")
export Transition, CausalState, transition_graph, sample_next_transition, emission_distribution
export label, transitions, symbols, symboltype, probability

include("epsilonmachine.jl")
export EpsilonMachine, get_states, get_transitions, transition_matrix, distribution
export simulate, alphabet_size, topological_complexity, num_states, num_transitions
export statistical_complexity, entropy_rate, stationary_distribution

include("process.jl")
export golden_mean_process, even_process, biased_coin_process, periodic_process

include("statepartition.jl")

include("inference.jl")
export CSSR, infer_machine, history_stats

include("plotting.jl")
export plot_machine, DOTstring

end
