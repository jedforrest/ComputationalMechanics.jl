"""
    plot_machine(em; plot_kwargs...)

Plot the transition graph of an ε-machine using Graphviz.

Additional keyword arguments are forwarded to `plot_graphviz`.
"""
function plot_machine(em::EpsilonMachine; plot_kwargs...)
    wg, attr = _set_graph_attributes(em.graph)

    plot_graphviz(wg, attr;
        edge_label=true,
        landscape=true,
        plot_kwargs...
    )
end

"""
    to_dot_file(em, output)

Write the ε-machine transition graph to a Graphviz DOT file.

The resulting file can be rendered with Graphviz or inspected directly.
"""
function to_dot_file(em::EpsilonMachine, output)
    wg, attr = _set_graph_attributes(em.graph)
    write_dot_file(wg, output; attributes=attr)
end


function _set_graph_attributes(mg::MetaGraph)
    wg, attr = from_metagraph(mg)

    # global properties
    set!(attr.plot_options, "weights", true)

    set!(attr.graph_options, "rankdir", "LR")

    set!(attr.node_options, "color", "black")
    set!(attr.node_options, "filled", true)
    set!(attr.node_options, "fillcolor", "lightblue")

    set!(attr.edge_options, "fontsize", 7.0)
    set!(attr.edge_options, "color", "black")
    set!(attr.edge_options, "fontcolor", "blue")

    # edges
    for e in attr.edges
        src, dst = e.from, e.to
        tr = _get_transition(mg, src, dst)
        label = "$(tr.symbol) | $(tr.probability)"
        set!(attr.edges, src, dst, Property("label", label))
        set!(attr.edges, src, dst, Property("weight", float(tr.probability)))
    end

    wg, attr
end


function _get_transition(mg::MetaGraph, src_code, dst_code)
    mg[label_for(mg, src_code), label_for(mg, dst_code)]
end
