#require './lib/graph_spec.rb'
require 'pry'
  
=begin
REFACTORING:
1. Create regex pattern for data: 
\d{2}:\d{2} for dep / arr
(\d+\.\d{2}) for price

2. Create object with a block interface
3. Array, not Hash in process_indices
4. Test with objects
5. Latch the paths algorithm to objects
6. Test with price
7. Create time_digify function, test 
9. Test all together on 3 random graphs
=end  
  
class RouteSolver
  
  class Route
    attr_accessor :from, :to, :dep, :arr, :price
  end
  
  def initialize(file)
  end
  
  #private
  
  #make sense of how the input is structured
  def gather_indices(file)
    indices = []
    File.open(file) do |f| 
      f.gets
      while line = f.gets
        if line.match /(^\d{1,1}$)/
          num = f.lineno
          inc = line.strip.to_i
          indices << [num, inc].join('-')
        end         
      end
    end
    indices
  end
  
  def foo(file_path) 
    File.open(file_path) do |f|
      create_routes(f, gather_indices(f))
    end
  end
  
  def create_routes(file, indices)
    indices.map do |index| 
      digits = index.split('-')
      num = digits[0].to_i
      inc = digits[1].to_i
      routes = []
      while inc > 0
        routes << create_route(file, num)
        num += 1
        inc -= 1
      end
      routes
    end
  end
  
  def create_route(file, number)
    lines =  File.open(file).readlines
    data = lines[number].split(' ')
    route = Route.new
    route.from =  data[0]
    route.to =    data[1]
    route.dep =   data[2] 
    route.arr =   data[3]
    route.price = data[4]
    route
  end
  
  def paths(path, routes, edge="")
    path = path + edge
    adjacent = neighbors(path, routes)
    return path if adjacent.empty?
    routes = routes - adjacent
    adjacent.map do |edge| 
      paths(path, routes, edge)
    end.flatten 
  end
  
  def adjacent(from, to)
    from[from.size-1] == to[0]
  end
  
  def neighbors(path, routes)
    routes.select do |route|
      adjacent(path, route)
    end
  end
  
end

require 'minitest/spec'
require 'minitest/autorun'

describe "RouteSolver" do 
  before do
    @file = 'files/sample-input-test.txt'
    @solver = RouteSolver.new(@file)
  end

  describe "test correct gathering of route indices" do 
     it "must create an array with the correct numbers" do 
       indices = @solver.gather_indices(@file)
       indices.must_equal ['3-1', '6-2']
     end  
  end

  describe "test creation of routes from a file and index" do 
    it "must instantiate an object with proper attributes" do 
      route = @solver.create_route(@file, 3)
      route.from.must_equal  'A'
      route.to.must_equal    'B'
      route.dep.must_equal   '09:00'
      route.arr.must_equal   '10:00'
      route.price.must_equal '100.00'
    end  
  end

  describe "test creation of route objects from an array of indices" do
    it "must contain the right number of correct objects" do
      routes = @solver.create_routes(@file, ['3-1', '6-2']) 
      routes.length.must_equal 2
      first_route = routes[0]
      first_route.length.must_equal 1
      second_route = routes[1]
      second_route.length.must_equal 2
      first_route[0].price.must_equal '100.00'
      second_route[0].price.must_equal '50.00'
      second_route[1].price.must_equal '300.00'
    end
  end
  
  describe "test foo function" do 
    it "must do foo" do
      routes = @solver.foo('files/sample-input-test.txt')
      routes.length.must_equal 2
      first_route = routes[0]
      first_route.length.must_equal 1
      second_route = routes[1]
      second_route.length.must_equal 2
      first_route[0].price.must_equal '100.00'
      second_route[0].price.must_equal '50.00'
      second_route[1].price.must_equal '300.00'
    end
  end
  
  describe "testing the core algorithm" do
    before do 
      @path = 'AB'
      @routes = ['AB', 'AB', 'AC', 'BC', 'BZ', 'CB', 'CZ']
    end
    it "must return an empty array when no neighbors exist" do
      @solver.neighbors('AQ', @routes).must_equal []
    end
    it "must return the correct neighbors for single-edge path (base case)" do
      @solver.neighbors(@path, @routes).must_equal ['BC', 'BZ']
    end
    it "must return the correct neighbors for multiple-edge path (composite case)" do
      @solver.neighbors('ABBC', @routes).must_equal ['CB', 'CZ']
    end
    it "must return the path when called with no adjacent edges (base case)" do
       @routes = ['AB', 'AB', 'AC', 'CB', 'CZ']
       @solver.paths(@path, @routes).must_equal 'AB'
    end
    it "must return the list of paths (recursive case)" do
      routes = @solver.paths(@path, @routes)
      routes.must_equal ['ABBCCB', 'ABBCCZ', 'ABBZ']
      @path = 'AC'
      routes = @solver.paths(@path, @routes)
      routes.must_equal ['ACCBBC', 'ACCBBZ', 'ACCZ']
    end
    it "must handle deep recursion (recursive case)" do
      @routes = ['AB', 'AB', 'AC', 'BC', 'BQ', 'BZ', 'CB', 'CZ', 'ZQ']
      routes = @solver.paths(@path, @routes)
      routes.must_equal ['ABBCCB', 'ABBCCZZQ', 'ABBQ', 'ABBZZQ']
    end
    it "must handle duplicate routes" do
      @routes = ['AB', 'BC', 'BC']
      routes = @solver.paths(@path, @routes)
      routes.must_equal ['ABBC', 'ABBC']
    end
  end
  
    
end

=begin
#route = false if line.match /^\s/
#line.match(/^[A-Z]/) ? data = true : data = false
=end

=begin
    puts "PATH: " + path
    puts "ADJACENT: " + adjacent.to_s
    puts "ROUTES: " + routes.to_s
=end
