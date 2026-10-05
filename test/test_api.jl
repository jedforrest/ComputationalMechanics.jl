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

ep = even_process(0.6)
ep.states
ep.startstate = "B"

fhp = feldman_hanna_process()

N = 1000
ss = simulate(String, ep, N)

text = "banana"^50
text = ss

inference = infer_machine(CSSR(), text, min_count=5, max_history=5)

machine = inference.machine
machine.states
ss_inferred = simulate(machine, N)

# inferred
count(x -> x == '1', ss_inferred)
count(x -> x == '0', ss_inferred)
# original
count(x -> x == '1', ss)
count(x -> x == '0', ss)


using PlotGraphviz, Graphs, MetaGraphsNext
ep = even_process(0.6)
fhp = feldman_hanna_process()

wg, attr = from_metagraph(ep.graph, weight_key="weight")
wg
attr

wg.weights = Graphs.weights(ep.graph)

wg.weights

attr.plot_options
attr.node_options
attr.edge_options
set!(attr.plot_options, "weights", true)
set!(attr.node_options, "color", "blue")
attr.nodes
attr.nodes[1].name
attr.nodes[1].attributes
# TODO set edges weights to correct probability weights
# also set edge display labels
src, dst = attr.edges[2].from, attr.edges[2].to
attr.edges

ep.graph["A", "B"]
ep.graph[1, 2]


plot_graphviz(wg, attr;
    edge_label=true,
    landscape=true,
)

plot_machine(ep)
to_dot_file(ep, "./test/ep.dot")

plot_machine(fhp)
to_dot_file(fhp, "./test/fhp.dot")
