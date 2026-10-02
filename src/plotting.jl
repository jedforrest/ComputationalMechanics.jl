function plot_machine(em::EpsilonMachine)
    # TODO customisation for epsilon machines
    plot_graphviz(em.graph)
end


function DOTstring(em::EpsilonMachine)
    # write DOT format to temp file then read it back
    return mktemp() do file, _
        savegraph(file, em.graph, DOTFormat())
        read(file, String)
    end
end
