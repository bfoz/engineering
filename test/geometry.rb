require 'minitest/autorun'
require 'geometry'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Geometry do
    let(:pointA) { Point[2.meters, 3.meters] }
    let(:pointB) { Point[4.meters, 5.meters] }
    let(:sizeA) { Size[2.meters, 3.meters] }
    let(:sizeB) { Size[4.meters, 5.meters] }

    describe "Point and Size arithmetic" do
	it "should add" do
	    sum = (pointA + sizeA)
	    sum.must_be_instance_of(Point)
	    sum.must_equal Point[4.meters, 6.meters]
	end
    end
end
