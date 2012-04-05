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
  
  class Flight
    attr_accessor :from, :to, :dep, :arr, :price
    
    def initialize
      yield self
    end
  end
  
  class Route 
    attr_reader :flights
    
    def initialize(flights)
      @flights = flights
    end
  end
  
  def initialize(file)
  end
  
  def foo(file_path) 
    File.open(file_path) do |f|
      create_schedules(f, gather_indices(f))
    end
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
  
  def create_schedules(file, indices)
    indices.map do |index| 
      digits = index.split('-')
      num = digits[0].to_i
      inc = digits[1].to_i
      schedules = []
      while inc > 0
        schedules << create_flight(file, num)
        num += 1
        inc -= 1
      end
      schedules
    end
  end
  
  def create_flight(file, number)
    lines =  File.open(file).readlines
    data = lines[number].split(' ')
    flight = Flight.new do |f|
      f.from =  data[0] 
      f.to =    data[1]
      f.dep =   data[2] 
      f.arr =   data[3]
      f.price = data[4]
    end
    flight
  end
  
  def paths(flight, routes, flt=[])
    flight = [flight] unless flight.respond_to? :length
    flights = flight + flt
    adjacent = neighbors(flights, routes)
    return [Route.new(flights)] if adjacent.empty?
    routes = routes - adjacent
    adjacent.map do |flt| 
      paths(flights, routes, [flt])
    end.flatten
  end
  
  def adjacent(flight1, flight2)
    flight1.to == flight2.from
  end
  
  def neighbors(flights, schedule)
    schedule.select do |flt|
      adjacent(flights.last, flt)
    end
  end
  
end

require 'minitest/spec'
require 'minitest/autorun'

describe "RouteSolver" do 
  before do
    @file = 'files/sample-input.txt'
    @solver = RouteSolver.new(@file)
  end

  describe "test correct gathering of route indices" do 
     it "must create an array with the correct numbers" do 
       indices = @solver.gather_indices(@file)
       indices.must_equal ['3-3', '8-7']
     end  
  end

  describe "test creation of routes from a file and index" do 
    it "must instantiate an object with proper attributes" do 
      flight = @solver.create_flight(@file, 3)
      flight.from.must_equal  'A'
      flight.to.must_equal    'B'
      flight.dep.must_equal   '09:00'
      flight.arr.must_equal   '10:00'
      flight.price.must_equal '100.00'
    end  
  end

  describe "test creation of route objects from an array of indices" do
    it "must contain the right number of correct objects" do
      routes = @solver.create_schedules(@file, ['3-3', '8-7']) 
      routes.length.must_equal 2
      first_route = routes[0]
      first_route.length.must_equal 3
      second_route = routes[1]
      second_route.length.must_equal 7
      first_route[0].price.must_equal '100.00'
      first_route[2].price.must_equal '300.00'
      second_route[0].price.must_equal '50.00'
      second_route[6].price.must_equal '100.00'
    end
  end
  
  describe "testing the route creation algorithm" do
    before do 
      schedules = @solver.create_schedules(@file, ['3-3', '8-7']) 
      @schedule = schedules[1]
      @flight = @schedule[0]     
    end
    
    describe "testing neighboring routes" do
      it "must return an empty array when no neighbors exist (base case)" do
        flight = RouteSolver::Flight.new do |f|
          f.from =  'A'
          f.to =    'Q'
          f.dep =   '09:00' 
          f.arr =   '12:30'
          f.price = '50.99'
        end
        @solver.neighbors([flight], @schedule).must_equal []
      end

      it "must return the correct neighbors for a single flight (composite case)" do
        thahood = @solver.neighbors([@flight], @schedule)
        thahood.length.must_equal 2
        thahood[0].price.must_equal '75.00'
        thahood[1].price.must_equal '250.00'
      end

      it "must return the correct neighbors for multiple flights (composite case)" do
        flight1 = @schedule[0]
        flight2 = @schedule[3]
        thahood = @solver.neighbors([flight1, flight2], @schedule)
        thahood.length.must_equal 2
        thahood[0].price.must_equal '50.00'
        thahood[1].price.must_equal '100.00'
      end
    end
     
    describe "testing route generation" do
      it "must return the path when called with no adjacent edges (base case)" do
         @flight.to = 'Q'
         route = @solver.paths(@flight, @schedule)
         route.length.must_equal 1
         route[0].flights.must_equal [@flight]
      end

      it "must return the list of paths (recursive case)" do
        routes = @solver.paths(@flight, @schedule)
        routes.length.must_equal 3
        
        first_route = routes[0]
        first_route.flights.length.must_equal 3
        first_route.flights.first.price.must_equal '50.00'
        first_route.flights.last.price.must_equal '50.00'
        
        second_route = routes[1]
        second_route.flights.length.must_equal 3
        second_route.flights.first.price.must_equal '50.00'
        second_route.flights.last.price.must_equal '100.00'
        
        third_route = routes[2]
        third_route.flights.length.must_equal 2
        third_route.flights.first.price.must_equal '50.00'
        third_route.flights.last.price.must_equal '250.00'
      end
    end    
  end
end
    

=begin
[
  #<RouteSolver::Route:0x007fafe3959c10 @flights=
    [#<RouteSolver::Flight:0x007fafe395be70 @from="A", @to="B", @dep="08:00", @arr="09:00", @price="50.00">, 
     #<RouteSolver::Flight:0x007fafe395af98 @from="B", @to="C", @dep="10:00", @arr="11:00", @price="75.00">, 
     #<RouteSolver::Flight:0x007fafe395a570 @from="C", @to="B", @dep="15:45", @arr="16:45", @price="50.00">
    ]>,
  #<RouteSolver::Route:0x007fafe3959b70 @flights=
    [#<RouteSolver::Flight:0x007fafe395be70 @from="A", @to="B", @dep="08:00", @arr="09:00", @price="50.00">, 
     #<RouteSolver::Flight:0x007fafe395af98 @from="B", @to="C", @dep="10:00", @arr="11:00", @price="75.00">, 
     #<RouteSolver::Flight:0x007fafe395a020 @from="C", @to="Z", @dep="16:00", @arr="19:00", @price="100.00">
    ]>, 
  #<RouteSolver::Route:0x007fafe3959a30 @flights=
    [#<RouteSolver::Flight:0x007fafe395be70 @from="A", @to="B", @dep="08:00", @arr="09:00", @price="50.00">, 
     #<RouteSolver::Flight:0x007fafe395aa20 @from="B", @to="Z", @dep="15:00", @arr="16:30", @price="250.00">
    ]>
]
=end