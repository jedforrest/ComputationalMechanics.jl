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


plot_machine(ep)
plot_machine(machine)
