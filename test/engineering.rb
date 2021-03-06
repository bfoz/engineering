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
		extrude length:10 do
		    square 5
		end
	    end
	end

	it "must create a global constant" do
	    Object.constants.include?(:TestModel).must_equal true
	end

	it "must support creating instances of the subclass" do
	    TestModel.new.must_be_kind_of Model
	    TestModel.new.must_be_kind_of TestModel
	end

	it "must call the initializer block when constructed" do
	    TestModel.new.elements.count.must_equal 1
	    TestModel.new.elements.first.must_be_kind_of Model::Extrusion
	    TestModel.new.elements.first.length.must_equal 10
	end

	describe "when another model class is created with a new name" do
	    before do
		model :TestModel2 do
		    extrude length:5 do
			square 10
		    end
		end
	    end
	    subject { TestModel2.new }

	    it "must be able to make new instances" do
		subject.must_be_kind_of Model
		subject.must_be_instance_of TestModel2
		subject.wont_be_instance_of TestModel
	    end

	    it "must call the correct initializer block when constructed" do
		subject.elements.count.must_equal 1
		subject.elements.first.must_be_kind_of Model::Extrusion
		subject.elements.first.length.must_equal 5
	    end

	    describe "when the original Model class is used again" do
		let(:anotherTestModel) { TestModel.new }

		it "must call the correct initializer block when constructed" do
		    anotherTestModel.elements.count.must_equal 1
		    anotherTestModel.elements.first.must_be_kind_of Model::Extrusion
		    anotherTestModel.elements.first.length.must_equal 10
		end
	    end
	end
    end

    it 'must create a Model subclass inside of a Module' do
	module TestModule
	    model :TestModel5 do
	    end
	end

	TestModule.constants.include?(:TestModel5).must_equal true
    end

    describe 'when creating a Model subclass with attributes that have default values' do
	subject do
	    model do
		attribute :attribute0, 42
	    end
	end

	it 'must have the default value' do
	    subject.new.attribute0.must_equal 42
	end

	it 'must allow the default value to be overriden' do
	    subject.new(attribute0: 24).attribute0.must_equal 24
	end

	it 'must have class attributes' do
	    subject.attribute0.must_equal 42
	end

	it 'must not have a class setter' do
	    -> { subject.attribute0 = 5 }.must_raise NoMethodError
	end
    end

    describe 'when creating a Model subclass with read-only attributes that have default values' do
	subject do
	    model do
		attr_reader :attributeRO, 42
	    end
	end

	it 'must have the default value' do
	    subject.new.attributeRO.must_equal 42
	end

	it 'must not allow the default value to be overriden' do
	    -> { subject.new(attributeRO: 24) }.must_raise NoMethodError
	end

	it 'must have class attributes' do
	    subject.attributeRO.must_equal 42
	end

	it 'must not have a class setter' do
	    -> { subject.attributeRO = 5 }.must_raise NoMethodError
	end

	it 'must not have an instance setter' do
	    -> { subject.new.attributeRO = 6 }.must_raise NoMethodError
	end
    end

    describe "when creating an Extrusion subclass" do
	after do
	    Object.send(:remove_const, :TestExtrusion)
	end

	before do
	    extrusion :TestExtrusion do
		square 5
	    end
	end

	it "must create a global constant" do
	    Object.constants.include?(:TestExtrusion).must_equal true
	end

	it "must be a subclass of Extrusion" do
	    (TestExtrusion < Model::Extrusion).must_equal true
	end

	it 'must have a class attribute for the Sketch' do
	    TestExtrusion.sketch.ancestors.must_include Sketch
	end

	describe "when initializing a new instance" do
	    subject { TestExtrusion.new(length: 5) }

	    it "must create instances of the proper class" do
		subject.must_be_kind_of Model::Extrusion
	    end

	    it "must call the initializer block" do
		subject.length.must_equal 5
	    end
	end
    end

    describe 'when creating an Extrusion subclass with a length' do
	subject do
	    extrusion do
		length 10
		square 5
	    end
	end

	it 'must have a class attribute for the length' do
	    subject.length.must_equal 10
	end

	describe 'when initializing a new instance' do
	    it 'must reject a length argument' do
		-> { subject.new(length:5) }.must_raise ArgumentError
	    end

	    it 'must have the proper length' do
		subject.new.length.must_equal 10
	    end
	end
    end

    describe 'when creating an Extrusion subclass with attributes' do
	subject do
	    extrusion do
		attribute :attribute0
	    end
	end

	it 'must define the attributes' do
	    subject.new.must_be :respond_to?, :attribute0
	    subject.new.must_be :respond_to?, :attribute0=
	end

	it 'must have working accessors' do
	    test_model = subject.new
	    test_model.attribute0 = 42
	    test_model.attribute0.must_equal 42
	end

	it 'must be able to initialize the attribute during construction' do
	    subject.new(attribute0: 37).attribute0.must_equal 37
	end
    end

    describe "when creating a Model that uses global constants" do
	before do
	    LENGTH = 5
	    model :TestModel3 do
		extrude length: LENGTH do
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
	subject { TestSketch.new }

	it "must create a global constant" do
	    Object.constants.include?(:TestSketch).must_equal true
	end

	it "must support creating instances of the subclass" do
	    subject.must_be_kind_of Sketch
	    subject.must_be_kind_of TestSketch
	end

	it "must call the initializer block when constructed" do
	    subject.elements.count.must_equal 1
	    subject.elements.first.must_be_kind_of Geometry::Square
	end

	describe "when another sketch class is created with a new name" do
	    before do
		sketch :TestSketch2 do
		    square 10
		end
	    end
	    subject { TestSketch2.new }

	    it "must be able to make new instances" do
		subject.must_be_kind_of Sketch
		subject.must_be_kind_of TestSketch2
		subject.wont_be_kind_of TestSketch
	    end

	    it "must call the correct initializer block when constructed" do
		subject.elements.count.must_equal 1
		subject.elements.first.must_be_kind_of Geometry::Square
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

    describe "when creating a Polygon" do
	it "must create a Polygon" do
	    polygon = Polygon.build do
		start_at [0,0]
		right	1
		up	1
		left	1
		down	1
	    end
	    polygon.must_be_instance_of(Geometry::Polygon)
	end
    end

    describe "when creating a Polyline" do
	it "must create a Polyline" do
	    polyline = Polyline.build do
		start_at [0,0]
		right	1
		up	1
		left	1
		down	1
	    end
	    polyline.must_be_instance_of(Geometry::Polyline)
	end
    end
end
