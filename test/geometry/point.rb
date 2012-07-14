require 'minitest/autorun'
require 'geometry'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Geometry::Point do
    Point = Geometry::Point

    it "should not break normal Point construction" do
	Point[1,2].must_be_instance_of(Point)
    end
    
    describe "when the elements have units" do
	let(:pointA) { Point[2.meters, 3.meters] }
	let(:pointB) { Point[4.meters, 5.meters] }
	
	describe "arithmetic" do
	    it "should add" do
		(pointA+pointB).must_equal Point[6.meters, 8.meters]
	    end
	    
	    it "should subtract" do
		(pointB-pointA).must_equal Point[2.meters, 2.meters]
	    end
	    
	    it "should multiply by a constant" do
		(pointA * 2).must_equal Point[4.meters, 6.meters]
	    end
	    
	    it "should divide by a constant" do
		(pointB / 2).must_equal Point[2.meters, 2.meters]
		(pointB / 2.0).must_equal Point[2.meters, 2.5.meters]
	    end
	end
    end
end
