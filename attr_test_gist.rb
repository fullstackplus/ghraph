=begin
I have a hash whose keys I want to set as class methods for an object (using attr_accessor) and whose values
I want to pass to those class methods in a second pass. I'm using class_eval to do the first part, but the second
part has caused me some headache. Is eval() the only way this can work? In the code below, I have uncommented all 
the ways I tried before it worked with eval(). 

I am specifically interested in why calling send(:method, value) gives me "wrong number of 
arguments (1 for 0) (ArgumentError)" and calling instance_eval(:method = value) gives me "syntax error, unexpected '=', expecting '}'"

=end

attrs = {
  "foo" => 1,
  "bar" => 2,
  "baz" => 3
}

o = Object.new

attrs.each do |k, v|
  Object.class_eval {attr_accessor k.to_sym}
  #o.send(:foo, "#{v}")
  #o.send(k.to_sym) = v
  #o.send(k.to_sym, v)
  #o.send "#{k}=#{v}"
  #o.instance_eval {"#{k}= v"}
  #These two work:
  o.send("#{k}=", v)
  eval "o.#{k} = v"
end

#Wrong number of arguments:
#puts o.send(:foo, 1)
#Syntax error:
#o.instance_eval {:foo = 1}
  
require 'minitest/spec'
require 'minitest/autorun'

describe "set object attributes from a Hash" do
  it "must have the methods and return the correct values" do
    o.respond_to?(:foo).must_equal true
    o.respond_to?(:bar).must_equal true
    o.respond_to?(:baz).must_equal true
    o.respond_to?(:quux).must_equal false
    o.foo.must_equal 1  
    o.bar.must_equal 2
    o.baz.must_equal 3
  end
end

