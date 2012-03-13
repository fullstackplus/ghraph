require './lib/graph_spec.rb'

class RouteSolver
  
  def initialize(file)
    #collect_graphs(parse_file(file, process_indices(file)))
  end
  
  #private
  
  #make sense of how the input is structured
  def process_indices(file)
    schedules = {}
    File.open(file) do |f|
      f.gets
      while line = f.gets
        if line.match /(^\d{1,1}$)/
          num = f.lineno
          inc = line.strip.to_i
          schedules.store(num, num+inc-1)
        end         
      end
    end
    schedules
  end
  
  #load input into a Ruby data structure
  def parse_file(file, schedules)
    routes = []
    lines =  File.open(file).readlines
    schedules.each do |k, v|
      route = []
      while k <= v
        data = lines[k].split(' ')
        #http://stackoverflow.com/questions/3669974/create-hash-using-block-ruby
        @params = {
          "from" => data[0],
          "to" => data[1],
          "dep" => data[2],
          "arr" => data[3],
          "price" => data[4]
        }
        route << @params
        k = k + 1
      end
      routes << route
    end
    create_attributes @params
    routes
  end
  
  def create_attributes(params)
    params.keys.each do |k|
      Edge.class_eval {attr_accessor k.to_sym}
    end
  end
  
  #create graph objects from raw data structures
  def collect_graphs(routes)
    routes.map do |route|
      initialize_graph(route)
    end
  end 
  
  def initialize_graph(route)
    @g = Graph.new
    route.each do |attrs|
      from_node = Node.new attrs["from"]
      to_node = Node.new attrs["to"]
      @g.add_node from_node
      @g.add_node to_node
      edge = @g.add_edge(from_node, to_node)
      attrs.each do |k, v|
        eval "edge.#{k} = v" unless edge.send k
      end
    end
    @g
  end  
  
end

require 'minitest/spec'
require 'minitest/autorun'

describe "RouteSolver" do 
  before do
    @file = 'files/sample-input.txt'
    @solver = RouteSolver.new(@file)
    @schedules = @solver.process_indices(@file)
    @params = @solver.parse_file(@file, @schedules)
  end
  describe "input processing" do
    it "must parse the file correctly" do
      @schedules.must_equal({3=>5, 8=>14})
      @params.must_equal(
        [
          [
            {"from" => "A", "to" => "B", "dep" => "09:00", "arr" => "10:00", "price" => "100.00"},
            {"from" => "B", "to" => "Z", "dep" => "11:30", "arr" => "13:30", "price" => "100.00"},
            {"from" => "A", "to" => "Z", "dep" => "10:00", "arr" => "12:00", "price" => "300.00"}
          ],
          [
            {"from" => "A", "to" => "B", "dep" => "08:00", "arr" => "09:00", "price" => "50.00"},
            {"from" => "A", "to" => "B", "dep" => "12:00", "arr" => "13:00", "price" => "300.00"},
            {"from" => "A", "to" => "C", "dep" => "14:00", "arr" => "15:30", "price" => "175.00"},
            {"from" => "B", "to" => "C", "dep" => "10:00", "arr" => "11:00", "price" => "75.00"},
            {"from" => "B", "to" => "Z", "dep" => "15:00", "arr" => "16:30", "price" => "250.00"},
            {"from" => "C", "to" => "B", "dep" => "15:45", "arr" => "16:45", "price" => "50.00"},
            {"from" => "C", "to" => "Z", "dep" => "16:00", "arr" => "19:00", "price" => "100.00"}
          ]
        ]
      )
    end
  end
  describe "graph initialization" do
    before do
      @graph = @solver.initialize_graph(
        [
          {"from" => "A", "to" => "B", "dep" => "09:00", "arr" => "10:00", "price" => "100.00"},
          {"from" => "B", "to" => "Z", "dep" => "11:30", "arr" => "13:30", "price" => "100.00"},
          {"from" => "A", "to" => "Z", "dep" => "10:00", "arr" => "12:00", "price" => "300.00"}
        ])
    end
    it "must create a graph responding to the right methods" do 
      @graph.edges.size.must_equal 3
      @graph.edges["a_b"].dep.must_equal "09:00"
      @graph.edges["a_z"].price.must_equal "300.00"
    end
    it "must have a collection containing 2 graphs" do 
      @graphs = @solver.collect_graphs(@params)
      @graphs.size.must_equal 2
      ab = @graphs[0].edge('A', 'B')
      ab.wont_be_nil
      ab.id.must_equal 'a_b'
    end 
  end  
  describe "compute cheapest route by price" do
    before do
      @short = @solver.initialize_graph(
        [
          {"from" => "A", "to" => "B", "dep" => "09:00", "arr" => "10:00", "price" => "100.00"},
          {"from" => "B", "to" => "Z", "dep" => "11:30", "arr" => "13:30", "price" => "100.00"},
          {"from" => "A", "to" => "Z", "dep" => "10:00", "arr" => "12:00", "price" => "300.00"}
        ])
      @long = @solver.initialize_graph(
        [
          {"from" => "A", "to" => "B", "dep" => "08:00", "arr" => "09:00", "price" => "50.00"},
          {"from" => "A", "to" => "B", "dep" => "12:00", "arr" => "13:00", "price" => "300.00"},
          {"from" => "A", "to" => "C", "dep" => "14:00", "arr" => "15:30", "price" => "175.00"},
          {"from" => "B", "to" => "C", "dep" => "10:00", "arr" => "11:00", "price" => "75.00"},
          {"from" => "B", "to" => "Z", "dep" => "15:00", "arr" => "16:30", "price" => "250.00"},
          {"from" => "C", "to" => "B", "dep" => "15:45", "arr" => "16:45", "price" => "50.00"},
          {"from" => "C", "to" => "Z", "dep" => "16:00", "arr" => "19:00", "price" => "100.00"}
        ])
    end
    it "must return the path A, B, Z for the short route" do 
      a = @short.node 'A'
      z = @short.node 'Z'
      path = @short.shortest_path(a, z, :price)
      path.size.must_equal 2
      path.map {|edge| edge.id}.must_equal ['a_b', 'b_z']
    end
    it "must return the path A, B, C, Z for the long route" do 
      a = @long.node 'A'
      z = @long.node 'Z'
      path = @long.shortest_path(a, z, :price)
      #OMG. I was being a dumbass. Bad idea storing edges as unique strings of x, y
      puts @long.edges.to_s
      @long.edges.size.must_equal 7
      path.size.must_equal 3
      path.map {|edge| edge.id}.must_equal ['a_b', 'b_c', 'c_z']
    end
  end
end

=begin
#route = false if line.match /^\s/
#line.match(/^[A-Z]/) ? data = true : data = false
=end


=begin
describe Graph do
  before do
    @graph = Graph.new
  end
  describe "brand new object" do
    it "must contain two hashes" do
      @graph.nodes.must_equal Hash.new
      @graph.edges.must_equal Hash.new
    end
  end
end
=end