module TimeArithmetic
  def digify(time)
    time = time.split(':')
    digits = time.map {|val| val.to_f} 
    hr = digits[0]
    min = digits[1]
    min.eql?(0)? min : min = 1.00/(60.00/min)
    hr + min
  end

  def subtract(one, two)
    res = digify(one) - digify(two)
    res < 0? 24+res : res
  end
end

require 'minitest/spec'
require 'minitest/autorun'
include TimeArithmetic

describe "testing time" do 
  it "must create decimals from hour and minute strings" do
    digify('09:00').must_equal 9
    digify('14:30').must_equal 14.5
    digify('08:15').must_equal 8.25
    digify('10:45').must_equal 10.75
    digify('05:30').must_equal 5.5
  end

  it "must subtract a time point from a later time point" do
    subtract('09:00', '08:00').must_equal 1
    subtract('14:30', '13:00').must_equal 1.5
    subtract('23:30', '08:15').must_equal 15.25
    subtract('11:30', '20:15').must_equal 15.25
    subtract('13:30', '10:45').must_equal 2.75
    subtract('02:00', '21:30').must_equal 4.5
    subtract('05:30', '03:00').must_equal 2.5
    subtract('13:15', '00:00').must_equal 13.25
  end
end
