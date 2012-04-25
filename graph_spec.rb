class Node
  attr_reader :name, :id
  def initialize(name)
    @name = name
    begin
      @id = @name.downcase
    rescue => msg
      puts "Cannot create id for node from name: #{msg}"
      raise
    end
  end
end

class Edge
  attr_reader :from, :to, :id
  def initialize(from, to)
    begin
      @from, @to = from.name, to.name
      @id = [from.id, "_", to.id].join
    rescue => msg
      puts "Cannot create id for edge from arguments: #{msg}"
      raise
    end
  end
end

class Graph
  attr_reader :nodes, :edges
  def initialize
    @nodes = {}
    @edges = {}
  end
  
  #..........................................................................................
  #.........................................CORE ADT.........................................
  #..........................................................................................
  
  def has_node?(node_name)
    @nodes.has_key? node_name.downcase
  end
  
  def add_node(node)
    @nodes.store(node.id, node)
  end
  
  def delete_node(node)
    @nodes.delete node.id
  end
  
  def add_edge(from_node, to_node) 
    return false if !(has_node?(from_node.name) && has_node?(to_node.name)) #false or nil?
    e = Edge.new(from_node, to_node)
    @edges.store(e.id, e)
  end

  def delete_edge(from_node, to_node)
    @edges.delete [from_node.id, "_", to_node.id].join
  end
  
  def neighbors(node)
    #outgoing = @edges.keys.select {|k| k.match /#{node.id}_[a-z]/}.map {|k| @edges[k]}
    #outgoing.map {|e| @nodes[e.to.downcase]}
    node_ids = @edges.keys.select {|k| k.match /#{node.id}_[a-z]/}
    node_ids.map {|id| @nodes[id.split('_')[1]]}
  end
  
=begin
  TODO: 
  a = Node.new 'A'
  b = Node.new 'B'
  ab = @graphs[0].adjacent?(a, b)
  
  So this will return an edge with the id composed of these two new nodes' ids.
  This is a bug - the graph does NOT contain these two nodes, but two other nodes 
  with the same names. So the edge returned will not be connected in any way to the 
  two nodes it was originally constructed with, because there's a disconnect: ids are based
  on primitive values, but what is returned are objects. For correct computation of equality,
  primitive values need to be checked against primitive values and objects against objects. 
  
  This just goes to show that everything, even in the simplest (and the most complex) program, 
  utlimately centers around:
  
  1) Data representation - primitive or object
  2) Object identtity and equality
  3) Basic data structures. Everything falls back on these
  4) "Things" and their properties, ie key / value pairs
  
In a complex program, this is merely hidden under layer upon layer of abstractions. But that is the base layer
every program ultimately functions on. Now what's cool about Lisp and data-driven, functional programming
(Christophe Grand's term for it is "relational-oriented programming" - http://clj-me.cgrand.net/2011/08/19/conways-game-of-life/) 
is that this layer is brought from the bottom level to the surface, and expressed in a very transparent, 
explicit, literal, & simplified way. As a result, many unnecessary levels of abstraction are stripped away
and only the essentials (data and functions) remain. Objects are replaced by simple recorrds or containers 
(essentially, groupings of properties and their values, key-value pairs). This is why JavaScript objects are
so similar to Hash Tables.
=end  

  def adjacent?(from_node, to_node)
    id = [from_node.id, "_", to_node.id].join
    @edges[id]
  end
  
  #....................................Extra getter methods..................................
  def node(node_name)
    @nodes[node_name.downcase]
  end
  
  #TODO: Duplicates adjacent?
  def edge(from_node_name, to_node_name)
    id = [from_node_name.downcase, "_", to_node_name.downcase].join
    @edges[id]
  end

  #..........................................................................................
  #.........................................PATH API.........................................
  #..........................................................................................
  
  require 'pry'
  
  def path(from_node, to_node, edges=[])
    edge = adjacent?(from_node, to_node)
    return edges + [edge] if edge
    neighbors(from_node).each do |node| 
      edges = edges + [adjacent?(from_node, node)]
      p = path(node, to_node, edges)
      return p if p
    end
    nil
  end
  
  def paths(from_node, to_node)
    @paths = []
    edge = adjacent?(from_node, to_node)
    @paths << [edge] if edge  
    neighbors(from_node).each do |node|       
      edge = [adjacent?(from_node, node)]    
      edge = nil if from_node.id.eql? node.id
      p = path(node, to_node) 
      if p && edge
        p = edge + p
        @paths << p
      end
    end
    return @paths if !@paths.empty? 
    nil
  end
  
  def cost_of_path(path, attrib)
    #return nil if Edge.respond_to? attrib
    #puts Edge.respond_to?(attrib).to_s + " IS IT?"
    #AttributeNotDefinedException
    path.map {|edge| edge.send(attrib)}.reduce {|acc, value| acc + value}
  end
  
  def shortest_path(from_node, to_node, attrib)
    paths = paths(from_node, to_node)
    costs = paths.map {|path| cost_of_path(path, attrib)}
    paths[costs.index(costs.min)]
  end
  
end




require 'minitest/spec'
require 'minitest/autorun'

#..........................................................................................
#.................................OBJECT INITIALIZATION TESTS..............................
#..........................................................................................

describe Node do
  before do
    @a = Node.new('A')
    @b = Node.new('B')
  end

  describe "brand new object" do
    it "must initialize properly" do
      @a.wont_be_nil
      @a.id.must_equal 'a'
    end
    it "must not initiaiaze given non-string args" do
      lambda { Node.new(22) }.must_raise(NoMethodError)
    end
  end
  
  describe Edge do
    it "must initialize properly" do
      e = Edge.new(@a, @b)
      e.wont_be_nil
      e.id.must_equal 'a_b'
    end
    it "must not initialize given non-string args" do
      lambda { Edge.new(22, 73) }.must_raise(NoMethodError)
    end
  end
end

#..........................................................................................
#.......................................CORE ADT TESTS.....................................
#..........................................................................................

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
  
  describe "node operations" do
    before do
      @a = Node.new 'A'
    end
    it "must return false if node does not exist" do
      @graph.has_node?('A').must_equal false
    end
    it "must return the node when a node is stored successfully" do
      @graph.add_node(@a).must_equal @a
    end
    it "must return true if node exists" do
      @graph.add_node @a
      @graph.has_node?('A').must_equal true
    end
    it "must return the node when it is deleted successfully" do
      @graph.add_node @a
      @graph.delete_node(@a).must_equal @a
      @graph.has_node?('A').must_equal false
    end
    it "must return nil when trying to delete a node that doesn't exist" do
      @graph.delete_node(@a).must_equal nil
    end
    it "must be able to override the old node when adding a node with the same id" do
      one = @graph.add_node(@a)
      other = @graph.add_node(Node.new 'A')
      one.id.must_equal other.id
      one.object_id.wont_equal other.object_id
    end
  end

  describe "edge operations" do
    before do
      @a = Node.new 'A'
      @b = Node.new 'B'
      @c = Node.new 'C'
      @graph.add_node @a
      @graph.add_node @b
    end
    it "must return false if either of nodes doesn't exist when adding an edge" do
      @graph.add_edge(@a, @c).must_equal false
    end
    it "must be able to override the old node when adding a node with the same id" do
      one = @graph.add_edge(@a, @b)
      other = @graph.add_edge(@a, @b)
      one.id.must_equal other.id
      one.object_id.wont_equal other.object_id
    end
    it "must return the edge when it is added successfully" do
      @graph.add_edge(@a, @b).id.must_equal 'a_b'
    end
    it "must return the edge when it is deleted successfully" do
      @graph.add_edge(@a, @b)
      @graph.delete_edge(@a, @b).id.must_equal 'a_b'
    end
    it "must return nil when trying to delete an edge that doesn't exist" do
       @graph.delete_edge(@a, @c).must_equal nil
    end
    it "must return a list of adjacent nodes given a node" do   
      @graph.add_node @c
      @graph.add_edge(@a, @b)
      @graph.add_edge(@a, @c)
      @graph.add_edge(@b, @c)
      @graph.neighbors(@a).must_equal [@b, @c]
      @graph.neighbors(@b).must_equal [@c]
      @graph.neighbors(@c).must_equal []
    end
    it "must return the connecting edge when given two connected edges" do
      e = @graph.add_edge(@a, @b)
      @graph.adjacent?(@a, @b).must_equal e
    end
    it "must return nil given two unconnected edges" do
       @graph.adjacent?(@a, @b).must_equal nil
    end
  end
  
  describe "node and edge getters" do
    before do 
      @a = Node.new 'A'
      @b = Node.new 'B'
      @c = Node.new 'C'
      @graph.add_node @a
      @graph.add_node @b
      @graph.add_node @c
      @ab = @graph.add_edge(@a, @b)
      @ac = @graph.add_edge(@a, @c)
    end
    it "must fail with bad arguments" do
      #TODO
    end
    it "must return the node when passed its name" do
      @graph.node('A').must_equal @a
    end
    it "must return nil when passed the name of a node not in graph" do
      @graph.node('Z').must_be_nil
    end
    it "must return the edge when passed the names of two nodes" do
      @graph.edge('A', 'B').must_equal @ab
    end
    #TODO: Should be a difference between the two
    it "must return nil when node does not exist" do
      @graph.edge('B', 'C').must_be_nil
    end
    it "must return nil when either of the nodes passed are not in graph" do
       @graph.edge('A', 'Z').must_be_nil
    end
  end

 #..........................................................................................
 #.......................................PATH API TESTS.....................................
 #..........................................................................................

  describe "Path API" do
    before do 
      @a = Node.new 'A'
      @b = Node.new 'B'
      @c = Node.new 'C'
      @d = Node.new 'D'
      @e = Node.new 'E'
      @graph.add_node @a
      @graph.add_node @b
      @graph.add_node @c
      @graph.add_node @d
      @graph.add_node @e
      @ab = @graph.add_edge(@a, @b)
      @ac = @graph.add_edge(@a, @c)
      @bc = @graph.add_edge(@b, @c)
      @cd = @graph.add_edge(@c, @d)
    end
    it "must return nil if no path exists between the given nodes" do 
      @graph.path(@a, @e).must_equal nil
      @graph.path(@d, @a).must_equal nil
    end
    it "must return a list of one edge when a path between the given nodes is that edge (base case)" do
      @graph.path(@a, @b).must_equal [@ab]
      @graph.path(@a, @c).must_equal [@ac] #the straight way of getting from A to C - not via B
    end
    it "must return a list of edges when a path between the given nodes consists of those edges (recursive case)" do 
      @graph.path(@a, @d).must_equal [@ab, @bc, @cd]
    end
    it "must treat a cycle as a regular path (recursive case)" do 
      @ca = @graph.add_edge(@c, @a)
      @graph.path(@a, @a).must_equal [@ab, @bc, @ca]
    end
    it "must treat a self-cycle as a regular path (base case)" do 
      @aa = @graph.add_edge(@a, @a)
      @graph.path(@a, @a).must_equal [@aa]
    end
    it "must return nil when no paths exist between the two given nodes" do 
      @graph.paths(@a, @e).must_equal nil
      @graph.paths(@d, @a).must_equal nil
    end
    it "must return a list including all paths between the two given nodes (base case)" do 
       @graph.paths(@a, @b).must_equal [[@ab]]
    end
    it "must return a list including all paths between the two given nodes (more than one path)" do 
      @graph.paths(@a, @c).must_equal [[@ac], [@ab, @bc]]
      @graph.paths(@a, @d).must_equal [[@ab, @bc, @cd], [@ac, @cd]]
    end
    it "must return a list including all paths to the node - when they are self-cycles" do 
      @aa = @graph.add_edge(@a, @a)
      @graph.paths(@a, @a).must_equal [[@aa]]
    end
    it "must return a list including all paths to the node - when they are cycles" do 
      @aa = @graph.add_edge(@a, @a)
      @da = @graph.add_edge(@d, @a)
      @graph.paths(@a, @a).must_equal [[@aa], [@ab, @bc, @cd, @da], [@ac, @cd, @da]]
    end    
    describe "Shortest path testing" do
      before do
        class Edge
          attr_accessor :weight
        end
        #long cheap path
        @ab.weight = 1
        @bc.weight = 2
        @cd.weight = 3
        #short expensive path
        @ac.weight = 5    
      end
      it "must compute cost of one path" do
        path = [@ab, @bc, @cd]
        @graph.cost_of_path(path, :weight).must_equal 6
      end
      it "must return false when an unknown attribute is passed to cost function" do
        #TODO. Custom exception class appropriate here 
      end
      it "must compute the cheapest of given paths" do
          paths = @graph.paths(@a, @d)
          @graph.shortest_path(@a, @d, :weight).must_equal [@ab, @bc, @cd]  
          @ad = @graph.add_edge(@a, @d)
          @ad.weight = 1  
          @graph.shortest_path(@a, @d, :weight).must_equal [@ad]    
      end
    end
    
  end
end


=begin
[
  [
    [#<Edge:0x007fc962a05428 @to="B", @from="A", @id="a_b", @weight=1>, 
     #<Edge:0x007fc962a04ac8 @to="C", @from="B", @id="b_c", @weight=2>, 
     #<Edge:0x007fc962a046b8 @to="D", @from="C", @id="c_d", @weight=3>
    ], 
    [6]
  ], 
  
  [
    [#<Edge:0x007fc962a04fa0 @to="C", @from="A", @id="a_c", @weight=5>, 
     #<Edge:0x007fc962a046b8 @to="D", @from="C", @id="c_d", @weight=3>
    ], 
    [8]
  ]
]

=end

=begin
A -> B
A -> C
B -> C

(A(B, C), B(C))

AB
AC
BC
or
(AB, AC, BC)

=>

AB
ABC
AC
BC

When it makes sense:

Use common data structures (list, hash, set) instead of objects 
Convert objects with behaviour, state, and identity into simple records (containers of properties and their values)
Convert data structures to data structure literals (as in Ruby, Python, Clojure)u
Use primitive types / data literals (strings, integers, symbols) as substitutes for objects

These two belong to the theme of succinct DSs:
Pre-process data structures by running stringifying algorithms on them for future constant-time lookup (like 
calculating all paths in a graph and storing each path as a string of chars) 
Use string scanning algorithms to process stringified data in linear time.

Composing object litarals also possible JUST using strings / standard library classes, 
like Brian Marick explains in this screencast: http://vimeo.com/34522837

ruby-1.9.3-p0 :016 > h = {"a" => String.new}
 => {"a"=>""} 
ruby-1.9.3-p0 :017 > h = {"a" => String.new('A')}
 => {"a"=>"A"}
Then you just define an object that inherits from Hash, instead of the default Object. 
 
Question: when adding a node successfully, you get the node as return value. Same when yu delete a node.
When doing the above unsuccessfully, Ruby gives you nil back:
h = {}
 => {} 
h.store("a", String.new('A'))
 => "A" 
h.store("b", String.new('B'))
 => "B" 
h.delete("b")
 => "B" 
h
 => {"a"=>"A"} 
h.delete("c")
 => nil 

This is because the opposite of an non-nil object is the nil object. (Ruby is OO).
So now the question: when designing own data structures, do you return nil or false
when defining the methods? Maybe Nil Object as advocated in Confident Code by Avdi:
http://www.youtube.com/watch?v=T8J0j2xJFgQ

Look at my add_edge(from_node, to_node) method.

=end



