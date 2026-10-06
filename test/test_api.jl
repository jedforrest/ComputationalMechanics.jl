# This is the standard API we would like to replicate

machine = fit(CSSR(), y;
    max_history = 6,
    alpha = 0.001
)

# TODO
transducer = fit(TransCSSR(), u, y;
    max_history = 6,
    alpha = 0.001
)

predict(machine, history) # TODO
simulate(machine, 10_000)
filter(machine, y) # TODO

statistical_complexity(machine)
entropy_rate(machine)

plot(machine)

#-------------------------------------------------------------------------------------------
using ComputationalMechanics

using PlotGraphviz, Graphs, MetaGraphsNext
ep = even_process(0.6)
fhp = feldman_hanna_process()

plot_machine(ep)
to_dot_file(ep, "./test/ep.dot")

plot_machine(fhp)
to_dot_file(fhp, "./test/fhp.dot")


dot_str = mktemp() do file, io
    to_dot_file(em, file)
    read(file, String)
end
println(dot_str)


wg, attr = from_metagraph(ep.graph)
attr.plot_options
attr.graph_options

#-------------------------------------------------------------------------------------------
using ComputationalMechanics
using DataStructures

ep = even_process(0.6)
ep.states

dd = Distribution(['A', 'B', 'C'], [0.5, 0.4, 0.1])

cs = ep.states[1]
dist = emission_distribution(cs, 0:4)

ep.alphabet
label.(ep.states)
stationary_distribution(ep)

transitions(ep.states[1])

dd = Distribution(['A', 'B', 'C'], [0.5, 0.4, 0.1])
dd['D'] = 0
dd

dd['E']
haskey(dd, 'E')

dd

collect(values(dd))

Distribution{Int}(0)

dd = Distribution{Int}(0)
dd[1] = 0.5
dd[2] = 0.8

dd
