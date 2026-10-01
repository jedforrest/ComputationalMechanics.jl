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
using SuffixAutomata
using HypothesisTests: ChisqTest, pvalue

ep = ComputationalMechanics.even_process(0.4)
ep.states

ss = simulate(String, ep, 100)

text = "banana"^20
# text = "mississippi"
text = ss
# text = 0:5
automaton = SuffixAutomaton(text)
H = history_stats(automaton, max_depth=5)

inference = infer_machine(CSSR(), text, min_count=5, max_history=5)

machine = inference.machine

# TODO plotting
