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
