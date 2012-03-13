#require './lib/graph_spec.rb'

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
  
  def create_paths(arr, from, to)
    @s = arr.map do |hash|
      hash.select {hash["from"] == from}
    end
    @s = @s.reject{|h| h == {}}
    puts "HERE IS SET: " + @s.to_s
    
    @q = @s.map {|hash| hash.select {hash["to"] == to}}
    @q = @q.reject{|h| h == {}}
    puts "HERE IS THE SECOND SET: " + @q.to_s
    puts "HERE IS DIFFEFRING SET: " + "#{@s - @q} "
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
    it "must do foo" do
      @solver.create_paths(@params[0], 'A', 'Z')
    end
   
  end
end

=begin
#route = false if line.match /^\s/
#line.match(/^[A-Z]/) ? data = true : data = false
=end
