require 'model'

class Model
    @elements = Array.new
    def self.elements
	super_elements = self.superclass.singleton_class.instance_method(:elements)
	super_elements.bind(self.superclass).call + @elements
    rescue
	@elements
    end

    def self.inherited(subclass)
	subclass.instance_variable_set(:@elements, [])
    end

    class << self
	private

	def push(*args)
	    @elements.push *args
	end
    end
end