#require './lib/graph_spec.rb'
require 'pry'
  
class RouteSolver
  
  def initialize(file)
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
    routes
  end
  
  def paths(path, routes, edge="")
    edges=[]
    path = path + edge
    adjacent = neighbors(path, routes)
    return path if adjacent.empty?
    routes = routes - adjacent
    adjacent.each do |edge| 
      edges << paths(path, routes, edge)
    end 
    edges.flatten
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
  describe "" do
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
