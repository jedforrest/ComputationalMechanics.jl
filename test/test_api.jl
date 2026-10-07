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
filter_states(machine, y) # TODO

statistical_complexity(machine)
entropy_rate(machine)

plot(machine)

#-------------------------------------------------------------------------------------------
using ComputationalMechanics
using DataStructures

em = golden_mean_process(0.6)
em.states

fhp = feldman_hanna_process()
labels(fhp)

N = 1000
y = simulate(fhp, N)

inference = infer_machine(CSSR(), y,
    max_history=6,
    min_count=5,
    alpha = 0.001
)
machine = inference.machine

histories(machine)

hist = y[end-50+1:end]
hist = "ABAAB"
predict(machine, hist)

filter_states(machine, hist)

valid_successors(fhp.states[5])

predict(machine, hist)
filter_states(machine, hist)

emission_distribution(fhp["AAA"])
