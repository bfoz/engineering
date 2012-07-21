require 'minitest/autorun'
require 'engineering'

describe Engineering do
    include Engineering::DSL

    after do
	# Cleanup the class constants created by each test
	ObjectSpace.each_object(Class).select {|k| k < Model}.each {|klass|
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
end
