# This is the standard API we would like to replicate

machine = fit(CSSR(), y;
    max_history = 6,
    alpha = 0.001
)

transducer = fit(TransCSSR(), u, y;
    max_history = 6,
    alpha = 0.001
)

predict(machine, history)
simulate(machine, 10_000)
filter(machine, y)

statistical_complexity(machine)
entropy_rate(machine)

plot(machine)

#-------------------------------------------------------------------------------------------
using ComputationalMechanics

ep = ComputationalMechanics.even_process(0.6)
ep.states

N = 1000
ss = simulate(String, ep, N)

text = "banana"^50
# text = "mississippi"
text = ss
# text = 0:5

inference = infer_machine(CSSR(), text, min_count=5, max_history=5)

machine = inference.machine
machine.states
machine.startstate
ss_inferred = simulate(machine, N)

# inferred
count(x -> x == '1', ss_inferred)
count(x -> x == '0', ss_inferred)
# original
count(x -> x == '1', ss)
count(x -> x == '0', ss)

# TODO stationary distribution
tm_ep = transition_matrix(ep)
tm_mi = transition_matrix(machine)
tm_ep^1000
tm_mi^1000

using Graphs, MetaGraphsNext, PlotGraphviz

plot_machine(ep)
plot_machine(machine)



using LinearAlgebra: eigen

P = [0 1; 1 0]
P = transition_matrix(machine)

stationary_distribution(ep)
stationary_distribution(machine)

pp = periodic_process('a':'f')
simulate(pp, 12)
stationary_distribution(pp)
