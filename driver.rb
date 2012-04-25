require './graph_spec'

g = Graph.new
g.add_edges('AB', 'BC', 'AC')
g.cost_of_path('A', 'C', :price)
