require 'minitest/autorun'
require 'geometry'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Geometry::Edge do
    Edge = Geometry::Edge

    let(:pointA) { Point[2.meters, 3.meters] }
    let(:pointB) { Point[4.meters, 5.meters] }
    
    describe "should construct an Edge from Points with Units" do
	let(:edge) { Edge.new(pointA, pointB) }

	it "should preserve the units" do
	    edge.first.must_equal Point[2.meters, 3.meters]
	    edge.last.must_equal Point[4.meters, 5.meters]
	end
    end

    it "must preserve units in the vector method" do
	Edge.new([0.meters, 0.meters], [1.meter, 0.meters]).vector.must_equal Point[1.meter, 0.meters]
    end

    it "must not preserve units in the direction method" do
	Edge.new([0.meters, 0.meters], [1.meter, 0.meters]).direction.must_equal Point[1, 0]
    end
end
