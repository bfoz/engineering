require 'model'

require_relative '../model/dsl'
require_relative 'extrusion'

module Engineering
    module Builder
	# Build a {Model} subclass
	class Model
	    include ::Model::DSL

	    # Convenience method for creating a new builder and evaluating a block
	    def self.build(&block)
		self.new.build(&block)
	    end

	    def initialize
		@attribute_defaults = {}
	    end

	    # Evaluate a block and return a new {Model} subclass
	    #  Use the trick found here http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	    #  to allow the DSL block to call methods in the enclosing *lexical* scope
	    def build(super_class=::Model, &block)
		@klass = Class.new(super_class)
		if block_given?
		    @klass.singleton_class.send :attr_reader, :elements
		    @klass.instance_variable_set(:@elements, [])

		    @self_before_instance_eval = block.binding.eval('self')
		    self.instance_eval(&block)

		    # Instance variable values for read-only attributes need special handling
		    options = @attribute_defaults.select {|k,v| @klass.respond_to? k.to_s + '=' } # Find the ones that can be set normally
		    instance_variable_defaults = @attribute_defaults.reject {|k,v| @klass.respond_to? k.to_s + '=' }	# These must be set directly

		    @klass.send :define_method, :initialize do |*args, &block|
			# Directly set the read-only instance variables
			instance_variable_defaults.each {|k,v| instance_variable_set('@' + k.to_s, v) }

			# Handle the others normally, while evaluating any blocks
			super(*(options.map {|k,v| { k => (v.respond_to?(:call) ? v.call : v) } }), *args, &block)

			# Push the default geometry
			self.class.instance_variable_get(:@elements).each do |a|
			    if a.is_a? Array
				push a.first.new(*a.last)
			    else
				push a
			    end
			end
		    end
		end
		@klass
	    end

	    # The second half of the instance_eval delegation trick mentioned at
	    #   http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	    def method_missing(method, *args, &block)
		if @klass.respond_to? method
		    @klass.send method, *args, &block
		else
		    @self_before_instance_eval.send method, *args, &block
		end
	    end

# @group DSL support methods
private

	    # Build a new {Extrusion} subclass
	    # @param length [Number]    the length of the extrusion
	    # @param sketch [Sketch]    a {Sketch} subclass to extrude (or nil)
	    # @param parent [Object]    a parent context to use while building
	    # @param options [Hash]	    anything that needs to be passed to the new {Extrusion} instance
	    def build_extrusion(length, sketch, parent, options={}, &block)
		[Builder::Extrusion.build(&block), [options.merge(length:length)]]
	    end

	    # Build a new {Group} subclass
	    def build_group(*args, &block)
		[self.class.new.build(::Model::Group, &block), args]
	    end

	    # Define an attribute with the given name and optional default value (or block)
	    # @param name [String]	The attribute's name
	    # @param value An optional default value
	    def define_attribute_reader(name, value=nil, &block)
		name, value = name.flatten if name.is_a?(Hash)
		ivar_name = '@' + name.to_s
		name = name.to_sym

		# Class accessor
		@klass.singleton_class.send :attr_reader, name

		@klass.send :attr_reader, name.to_sym	    # Instance accessor
		if value || block_given?
		    @klass.instance_variable_set(ivar_name, value || instance_eval(&block))
		    @attribute_defaults[name] = value || block
		end
	    end

	    # Define an attribute with the given name
	    # @param name [String,Symbol]   the name of the attribute
	    def define_attribute_writer(name)
		@klass.send :attr_writer, name.to_sym	    # Instance accessor
	    end

	    def push(element, *args)
		if element.is_a? Class
		    @klass.instance_variable_get(:@elements).push [element, args]
		elsif element.is_a?(Array) and element.first.is_a?(Class)
		    @klass.instance_variable_get(:@elements).push element
		else
		    raise ArgumentError, "Can't push instances while building a class"
		end
	    end
# @endgroup
	end
    end
end