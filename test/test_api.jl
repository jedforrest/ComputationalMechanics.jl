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


plot_graphviz(wg, attr;
    edge_label=true,
    landscape=true,
)

plot_machine(ep)
to_dot_file(ep, "./test/ep.dot")

plot_machine(fhp)
to_dot_file(fhp, "./test/fhp.dot")

plot_machine(machine)
