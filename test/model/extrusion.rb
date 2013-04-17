require 'minitest/autorun'
require 'model/extrusion'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Model::Extrusion do
    Extrusion = Model::Extrusion
    
    it "must not break normal construction" do
	Extrusion.new(length:5, sketch:Sketch.new).must_be_instance_of(Extrusion)
    end

    describe  "when the length parameter has units" do
	let(:extrusionA) { Extrusion.new length:5.meters, sketch:Sketch.new }
	
	it "must preserve the units" do
	    extrusionA.length.must_equal 5.meters
	end
    end
    
    describe  "when the length parameter is a variable with units" do
	let(:length) { 6.meters }
	let(:extrusionA) { Extrusion.new length:6.meters, sketch:Sketch.new }
	
	it "must preserve the units" do
	    extrusionA.length.must_equal 6.meters
	end
    end
end
