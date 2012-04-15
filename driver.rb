require './route_solver'

solver = RouteSolver.new('files/sample-input.txt')
solver.solve('A', 'Z')
solver.print('files/test-output.txt')
