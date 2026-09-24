p = Probability(0.3)
q = Probability(1.2)
q = Probability(0.2)

p + q
p + 5q
p * q
1 - p

#-------------------------------------------------------------------------------------------

t1 = Transition(0, 0.5, "A")
t2 = Transition(1, 0.5, "B")
t3 = Transition(0, 1.0, "A")
c1 = CausalState("A", [t1, t2])
c2 = CausalState("B", [t3])
states = [c1, c2]

g = transition_graph(states)

g["A", "B"]

typeof(g)

sample_next_transition(c1)

#-------------------------------------------------------------------------------------------

em = EpsilonMachine(states, "A")

eltype(em)
eltype(typeof(em))

W = transition_matrix(em)

Random.seed!(42)

collect(Iterators.take(em, 10))
join(Iterators.take(em, 50))
collect(Iterators.takewhile(!=(1), em))

num_states(em)
num_transitions(em)
alphabet_size(em)
topological_complexity(em)

#-------------------------------------------------------------------------------------------

gmp = golden_mean_process(0.3)
ep = even_process(0.8)
bcp = biased_coin_process(0.1)
pp = periodic_process(1:5)

join(Iterators.take(ep, 50))
ep.exact_distribution

join(Iterators.take(bcp, 50))

join(Iterators.take(pp, 25))
