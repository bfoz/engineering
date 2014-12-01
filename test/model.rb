require 'minitest/autorun'
require_relative '../lib/model'

describe Model do
    describe 'when subclassing Model' do
	let(:subclass) { Class.new(Model) }

	it 'must have an elements accessor' do
	    subclass.elements.must_equal []
	end

	it 'must not be modifiable' do
	    ->{ subclass.push }.must_raise NoMethodError
	end

	describe 'when subclassing a subclass of Model' do
	    let(:subsubclass) { Class.new(subclass) }

	    it 'must have grandchildren' do
		subclass.instance_variable_set(:@elements, [:a])
		subsubclass.instance_variable_set(:@elements, [:b])

		subsubclass.elements.must_equal [:a, :b]
	    end
	end
    end
end
