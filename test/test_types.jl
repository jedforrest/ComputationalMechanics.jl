transition_graph(name="foo")

t1 = Transition(0, 0.5, "A")
t2 = Transition(1, 0.5, "B")
t3 = Transition(0, 1.0, "A")
c1 = CausalState("A", [t1, t2])
c2 = CausalState("B", [t3])
states = [c1, c2]

g = transition_graph(states)

g["A", "B"]

typeof(g)

MetaGraph

#-------------------------------------------------------------------------------------------
typeof(states)

machine = EpsilonMachine(states, "A")


eltype(machine)
eltype(typeof(machine))
