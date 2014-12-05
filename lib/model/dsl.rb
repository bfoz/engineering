class Model
    # Extensions to Model::DSL
    module DSL
	# Define a new read-write {Model} attribute. An optional default value can be supplied as either an argument, or as a block. The block will be evaluated the first time the attribute is accessed.
	# @param name [String,Symbol]	The new attribute's name
	# @param value A default value for the new attribute
	def attr_accessor(name, value=nil, &block)
	    define_attribute_reader name, value, &block
	    define_attribute_writer name
	end
	alias :attribute :attr_accessor

	# Define a new read-only {Model} attribute.  An optional default value can be supplied as either an argument, or as a block. The block will be evaluated the first time the attribute is accessed.
	# @param name [String,Symbol]	The new attribute's name
	# @param value A default value for the new attribute
	def attr_reader(name, value=nil, &block)
	    define_attribute_reader(name, value, &block)
	end

	# Define a new write-only {Model} attribute
	# @param name [String,Symbol]	The new attribute's name
	def attr_writer(name)
	    define_attribute_writer(name)
	end

	# If the missing method happens to be the same as a known subclass of
	#  {Model}, then pass the call to the push method.
	def method_missing(method, *args, &block)
	    klass = Object.const_get(method)
	    if klass <= Model
		push klass, *args, &block
	    end
	rescue
	    super
	end
    end
end
