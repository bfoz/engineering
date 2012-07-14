require 'minitest/autorun'
require 'geometry'
require 'units'

# This is a bit of integration testing to ensure that the Units gem doesn't break
#  any of the other gems. None of the individual gems know about each other so
#  there's no way to test their integration at a lower level.

describe Geometry::Size do
    Size = Geometry::Size
    
    it "should not break normal Size construction" do
	Size[1,2].must_be_instance_of(Size)
    end
    
    describe "when the elements have units" do
	let(:sizeA) { Size[2.meters, 3.meters] }
	let(:sizeB) { Size[4.meters, 5.meters] }
	
	describe "arithmetic" do
	    it "should add" do
		(sizeA+sizeB).must_equal Size[6.meters, 8.meters]
	    end
	    
	    it "should subtract" do
		(sizeB-sizeA).must_equal Size[2.meters, 2.meters]
	    end
	    
	    it "should multiply by a constant" do
		(sizeA * 2).must_equal Size[4.meters, 6.meters]
	    end
	    
	    it "should divide by a constant" do
		(sizeB / 2).must_equal Size[2.meters, 2.meters]
		(sizeB / 2.0).must_equal Size[2.meters, 2.5.meters]
	    end
	end
    end
end
