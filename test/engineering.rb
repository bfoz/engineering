require 'minitest/autorun'
require 'engineering'

#LENGTH = 42

describe Engineering do
    include Engineering::DSL

    after do
	# Cleanup the class constants created by each test
	ObjectSpace.each_object(Class).select {|k| (k < Model) or (k < Sketch)}.each {|klass|
	    begin
		Object.send(:remove_const, klass.name.to_sym)
	    rescue NameError
	    end
	}
    end

    describe "when creating a named Model subclass" do
	before do
	    model :TestModel do
		extrude 10 do
		    square 5
		end
	    end
	end
	let(:testModel) { TestModel.new }

	it "must create a global constant" do
	    Object.constants.include?(:TestModel).must_equal true
	end

	it "must support creating instances of the subclass" do
	    TestModel.new.must_be_kind_of Model
	    TestModel.new.must_be_kind_of TestModel
	end

	it "must call the initializer block when constructed" do
	    TestModel.new.elements.count.must_equal 1
	    TestModel.new.elements.first.must_be_instance_of Model::Extrusion
	    TestModel.new.elements.first.length.must_equal 10
	end

	describe "when another model class is created with a new name" do
	    before do
		model :TestModel2 do
		    extrude 5 do
			square 10
		    end
		end
	    end
	    let(:testModel2) { TestModel2.new }

	    it "must be able to make new instances" do
		testModel2.must_be_kind_of Model
		testModel2.must_be_instance_of TestModel2
		testModel2.wont_be_instance_of TestModel
	    end

	    it "must call the correct initializer block when constructed" do
		testModel2.elements.count.must_equal 1
		testModel2.elements.first.must_be_instance_of Model::Extrusion
		testModel2.elements.first.length.must_equal 5
	    end

	    describe "when the original Model class is used again" do
		let(:anotherTestModel) { TestModel.new }

		it "must call the correct initializer block when constructed" do
		    anotherTestModel.elements.count.must_equal 1
		    anotherTestModel.elements.first.must_be_instance_of Model::Extrusion
		    anotherTestModel.elements.first.length.must_equal 10
		end
	    end
	end
    end

    describe "when creating a Model that uses global constants" do
	before do
	    LENGTH = 5
	    model :TestModel3 do
		extrude LENGTH do
		    square 5
		end
	    end
	end

	it "must not complain" do
	    TestModel3.new
	end

    end

    describe "when creating a named Sketch subclass" do
	before do
	    sketch :TestSketch do
		square 5
	    end
	end
	let(:testSketch) { TestSketch.new }

	it "must create a global constant" do
	    Object.constants.include?(:TestSketch).must_equal true
	end

	it "must support creating instances of the subclass" do
	    testSketch.must_be_kind_of Sketch
	    testSketch.must_be_kind_of TestSketch
	end

	it "must call the initializer block when constructed" do
	    testSketch.elements.count.must_equal 1
	    testSketch.elements.first.must_be_kind_of Geometry::Square
	end

	describe "when another sketch class is created with a new name" do
	    before do
		sketch :TestSketch2 do
		    square 10
		end
	    end
	    let(:testSketch2) { TestSketch2.new }

	    it "must be able to make new instances" do
		testSketch2.must_be_kind_of Sketch
		testSketch2.must_be_kind_of TestSketch2
		testSketch2.wont_be_kind_of TestSketch
	    end

	    it "must call the correct initializer block when constructed" do
		testSketch2.elements.count.must_equal 1
		testSketch2.elements.first.must_be_kind_of Geometry::Square
	    end

	    describe "when the original Sketch class is used again" do
		let(:anotherTestSketch) { TestSketch.new }

		it "must call the correct initializer block when constructed" do
		    anotherTestSketch.elements.count.must_equal 1
		    anotherTestSketch.elements.first.must_be_kind_of Geometry::Square
		end
	    end
	end
    end

end
