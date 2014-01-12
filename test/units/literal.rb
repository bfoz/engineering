require 'minitest/autorun'
require 'mathn'
require 'units'

# This is a bit of integration testing to ensure that the mathn gem doesn't break
#  the units gems. Mathn changes a number of the default arithmetic operators,
#  which tends to cause trouble for Units. Neither gem knows about the other so
#  there's no good way to test their integration at a lower level.

def Literal(*args)
    Units::Numeric.new(*args)
end

describe Units::Numeric do
    let(:one_meter)	{ Literal(1, :meter) }
    let(:three_meters)	{ Literal(3, :meters) }
    let(:four_meters)	{ Literal(4, :meters) }

    describe "coerced arithmetic" do
	it "division" do
	    (0 / one_meter).must_equal 0
	    (0 / three_meters).must_equal 0
#	    (4 / three_meters).must_equal Rational(4,3).meters
	    (12.0 / three_meters).must_equal four_meters
	end

	it "must divide a Rational" do
	    (Rational(2,1) / one_meter).must_equal Rational(2,1).meters(-1)
	end
    end
end
