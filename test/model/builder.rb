require 'minitest/autorun'
require 'model/builder'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Model::Builder do
    Builder = Model::Builder

    let(:builder) { Builder.new }

    describe "when adding an Extrusion with a length with units" do
	before do
	    builder.evaluate do
		extrude length:10.meters, sketch:Sketch.new do
		    rectangle size:[5, 6]
		end
	    end
	end
	
	it "should have an Extrusion element" do
	    builder.model.elements.last.must_be_instance_of Model::Extrusion
	    builder.model.elements.last.length.must_equal 10.meters
	end
	
	it "should make a Rectangle in the Extrusion's Sketch" do
	    extrusion = builder.model.elements.last
	    sketch = extrusion.sketch
	    sketch.elements.last.must_be_kind_of Geometry::Rectangle
	end
    end

end
