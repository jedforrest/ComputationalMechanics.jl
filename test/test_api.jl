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

predict(machine, history)
simulate(machine, 10_000)
filter_states(machine, y)

statistical_complexity(machine)
entropy_rate(machine)

plot(machine)

#-------------------------------------------------------------------------------------------
using ComputationalMechanics: SuffixAutomaton, history_stats, _sufficiency_phase, _determinism_phase, _build_machine

gmp = golden_mean_process(0.5)

N = 10_000
sequence = simulate(gmp, N)
alphabet=sort(unique(sequence))
max_history=6
min_count=5
alpha=0.05
statistical_test=:chi2

# Phase I: build suffix automaton on the sequence
automaton = SuffixAutomaton(sequence)
history = history_stats(automaton; max_depth=max_history)

# Phase II: level-by-level sufficiency testing
partition = _sufficiency_phase(history, alphabet, min_count)

# Phase III: ensure determinism (merge equivalent states)
partition = _determinism_phase(partition, history)

# Phase IV: build epsilon machine
machine = _build_machine(partition, history, alphabet, max_history)
