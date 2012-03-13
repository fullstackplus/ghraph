
attrs = {
  "foo" => 1,
  "bar" => 2,
  "baz" => 3
}

o = Object.new

attrs.each do |k, v|
  class << o
    #k is not visible from this scope!
    #attr_accessor k.to_sym
  end
  Object.class_eval do
    attr_accessor k.to_sym
  end
  #puts "OI: " + "#{k}=#{v}"
  #o.send(:foo, "#{v}")
  #o.send(k.to_sym) = v
  #o.send(k.to_sym, v)
  #o.send "#{k}=#{v}"
  #instance_eval {:k = v}
  eval "o.#{k} = v"
end

  
attrs.each do |k, v|
  #eval "o.#{k} = v"
end

puts o.foo  
puts o.bar
puts o.baz
  
require 'minitest/spec'
require 'minitest/autorun'

describe "" do

  it "" do
    #o = Object.new
    o.respond_to?(:foo).must_equal true
    o.respond_to?(:bar).must_equal true
    o.respond_to?(:baz).must_equal true
    o.respond_to?(:quux).must_equal false
    puts o.bar
    o.bar = 333
    puts o.bar
  end

end