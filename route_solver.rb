require './time-arithmetic'
include TimeArithmetic

class RouteSolver
  
  def initialize(input_file_path)
    File.open(input_file_path) do |f|
      @schedules = schedules(f, gather_indices(f))
    end
  end
    
  def solve(origin, destination)
    routes = @schedules.map {|sch| routes_between(sch, origin, destination)} 
    @results = routes.map do |route| 
      cheapest = lowest_by(:price, route)
      shortest = lowest_by(:duration, route) 
      results = cheapest + shortest
    end
  end
    
  def print(output_file_path)
    File.open(output_file_path, 'w') do |f|
      @results.each do |res|
        res.each do |route|
          f.write route.to_s
        end
        f.write "\n"
      end
    end
  end
  
  class Flight
    attr_accessor :from, :to, :dep, :arr, :prc
    
    def initialize
      yield self
    end
    
    def departure
      dep.to_f
    end
    
    def arrival
      arr.to_f
    end

    def price
      prc.to_f
    end
    
    def duration
      subtract(arr, dep)
    end
    
    def to_s
      "#{from} #{to} #{dep} #{arr} #{price}"
    end
  end
  
  class Route
    attr_reader :flights
    
    def initialize(flights)
      @flights = flights
    end
    
    def connects?(origin, destination)
      @flights.first.from.eql?(origin) && 
      @flights.last.to.eql?(destination)
    end

    def price
      @flights.map {|flt| flt.price}.reduce {|sum, price| sum += price} 
    end
    
    def duration
      subtract(@flights.last.arr, @flights.first.dep) 
    end
    
    def possible?
      @flights.each_cons(2) do |flights|
         if flights[1].departure < flights[0].arrival 
           return false
         end
       end
      true
    end
    
    def prc
      price.modulo(1).eql?(0.0)? price.to_s + '0' : price.to_s 
    end
    
    def to_s
      "#{@flights.first.dep} #{@flights.last.arr} #{prc}\n"
    end
  end
          
  #private
  
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
  
  def schedules(file, indices)
    indices.map do |index| 
      digits = index.split('-')
      num = digits[0].to_i
      inc = digits[1].to_i
      schedules = []
      while inc > 0
        schedules << flight(file, num)
        num += 1
        inc -= 1
      end
      schedules
    end
  end
  
  def flight(file, number)
    lines =  File.open(file).readlines
    data = lines[number].split(' ')
    flight = Flight.new do |f|
      f.from = data[0] 
      f.to   = data[1]
      f.dep  = data[2] 
      f.arr  = data[3]
      f.prc  = data[4]
    end
    flight
  end
  
  def routes(flight, schedule, flt=[])
    flight = [flight] if flt.empty?
    flights = flight + flt
    adjacent = neighbors(flights, schedule)
    return [Route.new(flights)] if adjacent.empty?
    schedule = schedule - adjacent
    adjacent.map do |flt| 
      routes(flights, schedule, [flt])
    end.flatten
  end
  
  def adjacent?(flight1, flight2)
    flight1.to == flight2.from
  end
  
  def neighbors(flights, schedule)
    schedule.select do |flt|
      adjacent?(flights.last, flt)
    end
  end
  
  def filter(routes, origin, destination)
    routes.select do |route| 
      route.connects?(origin, destination) 
    end
  end
  
  def routes_between(schedule, origin, destination)
    filter(schedule.select {|flt| flt.from.eql? origin}
    .map {|flt| routes(flt, schedule)}.flatten, 
    origin, destination)
    .select {|route| route.possible?}
  end
  
  def lowest_by(attrib, routes)
    lowest = routes.map {|route| route.send(attrib)}.min
    routes.select {|route| route.send(attrib).eql? lowest}
  end
end

require 'minitest/spec'
require 'minitest/autorun'
require 'pry'

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

  describe "test creation of Flight object given file and index" do 
    it "must instantiate an object with proper attributes" do 
      flight = @solver.flight(@file, 3)
      flight.from.must_equal  'A'
      flight.to.must_equal    'B'
      flight.dep.must_equal   '09:00'
      flight.arr.must_equal   '10:00'
      flight.prc.must_equal   '100.00'
    end  
  end

  describe "test creation of schedules from an array of indices" do
    it "must contain the right number of correct Flight objects" do
      schedules = @solver.schedules(@file, ['3-3', '8-7']) 
      schedules.length.must_equal 2
  
      first_schedule = schedules[0]
      first_schedule.length.must_equal 3
      first_schedule[0].prc.must_equal '100.00'
      first_schedule[2].prc.must_equal '300.00'
      
      second_schedule = schedules[1]
      second_schedule.length.must_equal 7
      second_schedule[0].prc.must_equal '50.00'
      second_schedule[6].prc.must_equal '100.00'
    end
  end
   
  describe "testing the route generation algorithm" do
    before do 
      @schedules = @solver.schedules(@file, ['3-3', '8-7']) 
      @schedule = @schedules[1]
      @flight = @schedule[0]     
    end
    
    describe "testing neighboring routes" do
      it "must return an empty array when no neighbors exist (base case)" do
        flight = RouteSolver::Flight.new do |f|
          f.from   = 'A'
          f.to     = 'Q'
          f.dep = '09:00' 
          f.arr = '12:30'
          f.prc = '50.99'
        end
        @solver.neighbors([flight], @schedule).must_equal []
      end

      it "must return the correct neighbors for a single flight (composite case)" do
        thahood = @solver.neighbors([@flight], @schedule)
        thahood.length.must_equal 2
        thahood[0].prc.must_equal '75.00'
        thahood[1].prc.must_equal '250.00'
      end

      it "must return the correct neighbors for multiple flights (composite case)" do
        flight1 = @schedule[0]
        flight2 = @schedule[3]
        thahood = @solver.neighbors([flight1, flight2], @schedule)
        thahood.length.must_equal 2
        thahood[0].prc.must_equal '50.00'
        thahood[1].prc.must_equal '100.00'
      end
    end
     
    describe "testing route generation" do
      it "must return the route when no neighboring flights exist (base case)" do
         @flight.to = 'Q'
         route = @solver.routes(@flight, @schedule)
         route.length.must_equal 1
         route[0].flights.must_equal [@flight]
      end

      it "must return the list of all possible routes given a flight and a list of scheduled flights (recursive case)" do
        routes = @solver.routes(@flight, @schedule)
        routes.length.must_equal 3

        first_route = routes[0]
        first_route.flights.length.must_equal 3
        first_route.flights.first.prc.must_equal '50.00'
        first_route.flights.last.prc.must_equal '50.00'
        
        second_route = routes[1]
        second_route.flights.length.must_equal 3
        second_route.flights.first.prc.must_equal '50.00'
        second_route.flights.last.prc.must_equal '100.00'
        
        third_route = routes[2]
        third_route.flights.length.must_equal 2
        third_route.flights.first.prc.must_equal '50.00'
        third_route.flights.last.prc.must_equal '250.00'
      end
    end
  end

  describe "testing connections betweeen route end points" do
    before do 
      @schedules = @solver.schedules(@file, ['3-3', '8-7']) 
      @schedule = @schedules[1]
      @flight = @schedule[0]     
    end
     
    it "must tell if the route connects two endpoints (more than one route)" do
      routes = @solver.routes(@flight, @schedule)
      routes[0].connects?('A', 'Z').must_equal false
      routes[1].connects?('A', 'Z').must_equal true
      routes[2].connects?('A', 'Z').must_equal true
    end

    it "must tell if the route connects two endpoints (one route)" do
      routes = @solver.routes(@flight, @schedule)
      first_route = routes[0]
      first_route.flights.pop
      first_route.flights.pop
      first_route.flights.length.must_equal 1
      first_route.connects?('A', 'B').must_equal true
    end

    it "must filter out routes that connect two given endpoints" do
      routes = @solver.routes(@flight, @schedule)
      filtered = @solver.filter(routes, 'A', 'Z')
      filtered.length.must_equal 2
      filtered[0].connects?('A','Z').must_equal true
      filtered[1].connects?('A','Z').must_equal true
    end

    it "must generate all valid routes between two given endpoints" do
      routes = @solver.routes_between(@schedule, 'A', 'Z')
      routes.length.must_equal 4
    end
  end

  describe "testing price and duration calculation for routes" do
    before do 
      @schedules = @solver.schedules(@file, ['3-3', '8-7']) 
      @schedule = @schedules[1]   
    end
    
    it "must calculate price for route" do
      routes = @solver.routes_between(@schedule, 'A', 'Z')
      routes[0].price.must_equal 225
      routes[3].price.must_equal 275  
    end

    it "must calculate route(s) with lowest price" do
      routes = @solver.routes_between(@schedule, 'A', 'Z')
      cheapest = @solver.lowest_by(:price, routes)
      cheapest.length.must_equal 1
      cheapest[0].price.must_equal 225  
    end

    it "must calculate duration for route" do
      routes = @solver.routes_between(@schedule, 'A', 'Z')
      routes[0].duration.must_equal 11  
      routes[3].duration.must_equal 5.0   
    end

    it "must calculate route(s) with lowest duration" do
      routes = @solver.routes_between(@schedule, 'A', 'Z')
      shortest = @solver.lowest_by(:duration, routes)  
      shortest.length.must_equal 1
      shortest[0].duration.must_equal 4.5 
    end
  end

  describe "pretty-printing of objects" do
    before do 
      @schedules = @solver.schedules(@file, ['3-3', '8-7']) 
      @schedule1 = @schedules[0]
      @schedule2 = @schedules[1]  
    end
    
    it "must print the objects" do
      routes = @solver.routes_between(@schedule1, 'A', 'Z')
      cheapest = @solver.lowest_by(:price, routes)
      shortest = @solver.lowest_by(:duration, routes) 
      results = cheapest + shortest
      results.length.must_equal 2
      text = <<-EOS.gsub(/^\s+/, '')
        09:00 13:30 200.00
        10:00 12:00 300.00
      EOS
      output = ""
      results.each {|route| output << route.to_s}
      output.must_equal text
      
      routes = @solver.routes_between(@schedule2, 'A', 'Z')
      cheapest = @solver.lowest_by(:price, routes)
      shortest = @solver.lowest_by(:duration, routes) 
      results = cheapest + shortest
      results.length.must_equal 2
      text = <<-EOS.gsub(/^\s+/, '')
        08:00 19:00 225.00
        12:00 16:30 550.00
      EOS
      output = ""
      results.each {|route| output << route.to_s}
      output.must_equal text
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

[
  #<RouteSolver::Route:0x007faf4b19a058 @flights=
    [#<RouteSolver::Flight:0x007faf4b192808 @from="A", @to="B", @dep="08:00", @arr="09:00", @price="50.00">, 1
     #<RouteSolver::Flight:0x007faf4b19bbb0 @from="B", @to="C", @dep="10:00", @arr="11:00", @price="75.00">, 1
     #<RouteSolver::Flight:0x007faf4b19a670 @from="C", @to="Z", @dep="16:00", @arr="19:00", @price="100.00"> 3
    ]>, 11
  #<RouteSolver::Route:0x007faf4b1a3b80 @flights=
    [#<RouteSolver::Flight:0x007faf4b192808 @from="A", @to="B", @dep="08:00", @arr="09:00", @price="50.00">, 1
     #<RouteSolver::Flight:0x007faf4b19b408 @from="B", @to="Z", @dep="15:00", @arr="16:30", @price="250.00"> 1,5
    ]>, 8,5
  #<RouteSolver::Route:0x007faf4b1a2e60 @flights=
    [#<RouteSolver::Flight:0x007faf4b19cc40 @from="A", @to="B", @dep="12:00", @arr="13:00", @price="300.00">, 1
     #<RouteSolver::Flight:0x007faf4b19bbb0 @from="B", @to="C", @dep="10:00", @arr="11:00", @price="75.00">,  1
     #<RouteSolver::Flight:0x007faf4b19a670 @from="C", @to="Z", @dep="16:00", @arr="19:00", @price="100.00">  3
    ]>, 7 - impossible
  #<RouteSolver::Route:0x007faf4b1a2cf8 @flights=
    [#<RouteSolver::Flight:0x007faf4b19cc40 @from="A", @to="B", @dep="12:00", @arr="13:00", @price="300.00">, 1
     #<RouteSolver::Flight:0x007faf4b19b408 @from="B", @to="Z", @dep="15:00", @arr="16:30", @price="250.00">  1,5
    ]>, 4,5
  #<RouteSolver::Route:0x007faf4b1a24b0 @flights=
    [#<RouteSolver::Flight:0x007faf4b19c538 @from="A", @to="C", @dep="14:00", @arr="15:30", @price="175.00">, 1,5
     #<RouteSolver::Flight:0x007faf4b19acb0 @from="C", @to="B", @dep="15:45", @arr="16:45", @price="50.00">,  1 
     #<RouteSolver::Flight:0x007faf4b19b408 @from="B", @to="Z", @dep="15:00", @arr="16:30", @price="250.00">  1,5
    ]>, 2,5 - impossible
  #<RouteSolver::Route:0x007faf4b1a22a8 @flights=
    [#<RouteSolver::Flight:0x007faf4b19c538 @from="A", @to="C", @dep="14:00", @arr="15:30", @price="175.00">, 1,5
     #<RouteSolver::Flight:0x007faf4b19a670 @from="C", @to="Z", @dep="16:00", @arr="19:00", @price="100.00">  3
    ]> 5
]
=end



#The toolkit that I'm quite comfortable with: processing of structured data, functional programming techniques, 
#graph and set theory, recursive algorithms, polymorphism.










