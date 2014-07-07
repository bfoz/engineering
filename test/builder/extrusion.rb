require 'minitest/autorun'
require 'builder/extrusion'

describe Engineering::Builder::Extrusion do
    subject { Engineering::Builder::Extrusion }

    it 'must build a subclass' do
	subject.build.ancestors.must_include(Model::Extrusion)
	Class.wont_be :respond_to?, :elements
    end

    it 'must build a subclass with an empty block' do
	klass = subject.build {}
	klass.ancestors.must_include(Model::Extrusion)
	klass.sketch.ancestors.must_include(Sketch)
	klass.sketch.elements.must_be_empty
    end

    it 'must build a subclass with a length property' do
	subject.build.must_be :respond_to?, :length
	Class.wont_be :respond_to?, :length
    end

    it 'must build a subclass with a sketch property' do
	subject.build.must_be :respond_to?, :sketch
	Class.wont_be :respond_to?, :sketch
    end

    it 'must have a length property that is availabe to the DSL' do
	subject.build() { length 5; length.must_equal 5 }
    end

    describe 'when creating a subclass with attributes' do
	let :klass do
	    subject.build do
		attribute :attribute0
	    end
	end

	it 'must define the attributes' do
	    klass.new.must_be :respond_to?, :attribute0
	    klass.new.must_be :respond_to?, :attribute0=
	end

	it 'must define the attribute on the Sketch instance' do
	    klass.new.sketch.must_be :respond_to?, :attribute0
	end

	it 'must have working accessors' do
	    test_model = klass.new
	    test_model.attribute0 = 42
	    test_model.attribute0.must_equal 42
	end

	it 'must be able to initialize the attribute during construction' do
	    klass.new(attribute0: 37).attribute0.must_equal 37
	end
    end

    describe 'when creating a subclass with attributes that have default values' do
	let :klass do
	    subject.build do
		attribute :attribute0, 42
	    end
	end

	it 'must define the attribute on the Sketch subclass' do
	    klass.sketch.must_be :respond_to?, :attribute0
	end

	it 'must have the default value' do
	    klass.new.attribute0.must_equal 42
	end

	it 'must allow the default value to be overriden' do
	    klass.new(attribute0: 24).attribute0.must_equal 24
	end

	it 'must not pollute Class' do
	    Class.wont_be :respond_to?, :attribute0
	end

	it 'must have class attributes' do
	    klass.attribute0.must_equal 42
	end

	it 'must not have a class setter' do
	    -> { klass.attribute0 = 5 }.must_raise NoMethodError
	end
    end

    describe 'when creating a subclass with read-only attributes that have default values' do
	let :klass do
	    subject.build do
		attr_reader :attributeO, 42
	    end
	end

	it 'must have the default value' do
	    klass.new.attributeO.must_equal 42
	end

	it 'must not allow the default value to be overriden' do
	    -> { klass.new(attributeO: 24) }.must_raise NoMethodError
	end

	it 'must not pollute Class' do
	    Class.wont_be :respond_to?, :attribute0
	end

	it 'must have class attributes' do
	    klass.attributeO.must_equal 42
	end

	it 'must not have a class setter' do
	    -> { klass.attributeO = 5 }.must_raise NoMethodError
	end

	it 'must not have an instance setter' do
	    -> { klass.new.attributeO = 6 }.must_raise NoMethodError
	end
    end

    describe 'when creating a subclass with a group' do
	let :klass do
	    subject.build do
		group origin:[1,2] do
		end
	    end
	end

	it 'must create a Group subclass' do
	    klass.sketch.elements.count.must_equal 1
	    klass.sketch.elements.first.first.ancestors.must_include Sketch::Group
	    klass.sketch.elements.first.last.must_equal [origin:[1,2]]
	end

	it 'must pass the initializer arguments when instantiating the subclass' do
	    klass.new.sketch.first.must_be_kind_of Sketch::Group
	    klass.new.sketch.first.transformation.translation.must_equal Geometry::Point[1,2]
	end
    end
end