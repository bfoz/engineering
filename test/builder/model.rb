require 'minitest/autorun'
require 'builder/model'

describe Engineering::Builder::Model do
    subject { Engineering::Builder::Model }

    it 'must build a Model subclass' do
	subject.build.ancestors.must_include(Model)
	Class.wont_be :respond_to?, :elements
    end

    it 'must build a Model subclass with an empty block' do
	klass = subject.build {}
	klass.ancestors.must_include(Model)
	klass.elements.must_be_empty
	Class.wont_be :respond_to?, :elements
    end

    describe 'when creating a Model subclass with attributes' do
	let :klass do
	    subject.build do
		attribute :attribute0
	    end
	end

	it 'must define the attributes for instances' do
	    klass.new.must_be :respond_to?, :attribute0
	    klass.new.must_be :respond_to?, :attribute0=
	end

	it 'must have working instance accessors' do
	    test_model = klass.new
	    test_model.attribute0 = 42
	    test_model.attribute0.must_equal 42
	end

	it 'must be able to initialize the attribute during construction' do
	    klass.new(attribute0: 37).attribute0.must_equal 37
	end
    end

    describe 'when creating a Model subclass with attributes that have default values' do
	let :klass do
	    subject.build do
		attribute :attribute0, 42
	    end
	end

	it 'must have the default value' do
	    klass.new.attribute0.must_equal 42
	end

	it 'must allow the default value to be overriden' do
	    klass.new(attribute0: 24).attribute0.must_equal 24
	end

	it 'must have class attributes' do
	    klass.attribute0.must_equal 42
	end

	it 'must not pollute Class' do
	    Class.wont_be :respond_to?, :attribute0
	end

	it 'must not have a class setter' do
	    -> { klass.attribute0 = 5 }.must_raise NoMethodError
	end
    end

    describe 'when creating a Model subclass with read-only attributes that have default values' do
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

    describe 'when pushing subclasses with initializer arguments' do
	let :klass do
	    subject.build do
		push Model, origin:[1,2,3]
	    end
	end

	it 'must store the subclass in initializer arguments' do
	    klass.elements.first.must_be_kind_of Array
	    klass.elements.first.must_equal [Model, [origin:[1,2,3]]]
	end

	it 'must pass the initializer arguments when instantiating the subclass' do
	    klass.new.elements.first.must_be_kind_of Model
	end
    end

    describe 'when creating a subclass with an extrusion' do
	let :klass do
	    subject.build do
		extrude length:10, origin:[1,2,3] do
		end
	    end
	end

	it 'must create an Extrusion subclass' do
	    klass.elements.count.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model::Extrusion
	    klass.elements.first.last.must_equal [length:10, origin:[1,2,3]]
	end

	it 'must pass the initializer arguments when instantiating the subclass' do
	    klass.new.first.must_be_kind_of Model::Extrusion
	    klass.new.first.transformation.translation.must_equal Geometry::Point[1,2,3]
	end
    end

    describe 'when creating a subclass with a group' do
	let :klass do
	    subject.build do
		group origin:[1,2,3] do
		end
	    end
	end

	it 'must create a Group subclass' do
	    klass.elements.count.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model::Group
	    klass.elements.first.last.must_equal [origin:[1,2,3]]
	end

	it 'must pass the initializer arguments when instantiating the subclass' do
	    klass.new.first.must_be_kind_of Model::Group
	    klass.new.first.transformation.translation.must_equal Geometry::Point[1,2,3]
	end
    end

    describe 'when creating a subclass with a stack layout' do
	let :klass do
	    subject.build do
		stack do
		end
	    end
	end

	it 'must create a Layout subclass' do
	    klass.elements.size.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model::Layout
	    klass.elements.first.last.first[:direction].must_equal :vertical
	end
    end

    describe 'when creating a subclass that contains another Model subclass' do
	let :klass do
	    subject.build do
		push Model
	    end
	end

	it 'must add the subclass' do
	    klass.elements.length.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model
	    klass.elements.first.last.must_equal []
	end
    end

    describe 'when creating a subclass that contains another Model subclass that has argument' do
	let :klass do
	    subject.build do
		push Model, origin:[1,2,3]
	    end
	end

	it 'must add the subclass' do
	    klass.elements.length.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model
	    klass.elements.first.last.must_equal [origin:[1,2,3]]
	end

	it 'must pass the initializer arguments when instantiating the subclass' do
	    klass.new.first.must_be_kind_of Model
	    klass.new.first.transformation.translation.must_equal Geometry::Point[1,2,3]
	end
    end

    describe 'shortcuts' do
	after { Object.send :remove_const, :Foo }

	it 'must have a shortcut for pushing a subclass without arguments' do
	    Foo = Class.new(Model)
	    klass = subject.build do
		Foo()
	    end

	    klass.elements.length.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model
	    klass.elements.first.last.must_equal []
	end

	it 'must have a shortcut for pushing a subclass with arguments' do
	    Foo = Class.new(Model)
	    klass = subject.build do
		Foo origin:[1,2,3]
	    end

	    klass.elements.length.must_equal 1
	    klass.elements.first.first.ancestors.must_include Model
	    klass.elements.first.last.must_equal [origin:[1,2,3]]
	end
    end
end
