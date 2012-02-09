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
  #true / false like a Ruby Hash
  def has_node?(node_name)
    @nodes.has_key? node_name.downcase
  end
  
  #return value is the elem like in a Ruby Hash
  def add_node(node)
    @nodes.store(node.id, node)
  end
  
  #return value is the elem like in a Ruby Hash. If elem does not exist return value is nil. 
  #Wait, this is stupid. It should be false not nil which is "falsey". How do we say:
  #if we deleted unsuccessfully, do this and not if the return value is nil do this?
  def delete_node(node)
    @nodes.delete node.id
  end
  
  #if given nodes exist, add an edge between them
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
  
  def adjacent?(from_node, to_node)
    id = [from_node.id, "_", to_node.id].join
    @edges[id]
  end
  #..........................................................................................
  #.......................................EXTRA METHODS......................................
  #..........................................................................................
  
end

require 'minitest/spec'
require 'minitest/autorun'

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

end


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

Convert objects / records / containers to common data structures (list, hash, set)
Convert data structures to data structure literals (as in Ruby, Python, Clojure)
Convert complex types / data to simple types / data literals (strings, integers, symbols)
Pre-process data structures by running stringifying algorithms on them for future constant-time lookup
(like calculating all paths in a graph and storing each path as a string of chars)
Use string scanning algorithms to process stringified data in linear time.

Composing object litarals also possible JUST using strings / standard library classes, 
like Brian Marick in that screencast:
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
when defining the methods? Look at my add_edge(from_node, to_node) method.

=end



