require 'sketch'

module Engineering
    module Builder
	class Sketch
	    include ::Sketch::DSL

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
	    def build(super_class=::Sketch, &block)
		@klass = Class.new(super_class)
		if block_given?
		    @klass.singleton_class.send :attr_accessor, :elements
		    @klass.instance_variable_set('@elements', [])

		    @self_before_instance_eval = block.binding.eval('self')
		    self.instance_eval(&block)

		    # Instance variable values for read-only attributes need special handling
		    setter_defaults = @attribute_defaults.select {|k,v| @klass.respond_to? k.to_s + '=' } # Find the ones that can be set normally
		    instance_variable_defaults = @attribute_defaults.reject {|k,v| @klass.respond_to? k.to_s + '=' }	# These must be set directly

		    @klass.send :define_method, :initialize do |*args, &block|
			# Directly set the read-only instance variables
			instance_variable_defaults.each {|k,v| instance_variable_set('@' + k.to_s, v) }

			super(setter_defaults, *args, &block)

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
		@self_before_instance_eval.send method, *args, &block
	    end

# @group DSL support methods
private

	    # Create a {Group} with an optional transformation
	    def build_group(*args, &block)
		[self.class.new.build(::Sketch::Group, &block), args]
	    end

	    # Create a {Layout}
	    # @param direction [Symbol] The layout direction (either :horizontal or :vertical)
	    # @option options [Symbol] alignment    :top, :bottom, :left, or :right
	    # @option options [Number] spacing  The spacing between each element
	    def build_layout(direction, alignment, spacing, *args, &block)
		[Builder::Sketch.new.build(::Sketch::Layout, &block), args]
	    end

	    # Use the given block to build a {Polyline}
	    def build_polyline(**options, &block)
		::Sketch::Builder::Polyline.new(**options).evaluate(&block)
	    end

	    # Build a {Polygon} from a block
	    # @return [Polygon]
	    def build_polygon(**options, &block)
		::Sketch::Builder::Polygon.new(**options).evaluate(&block)
	    end

	    # Define an attribute with the given name and optional default value (or block)
	    # @param name [String]	The attribute's name
	    # @param value An optional default value
	    def define_attribute_reader(name, value=nil, &block)
		name, value = name.flatten if name.is_a?(Hash)
		ivar_name = '@' + name.to_s
		name = name.to_sym

		# Class accessor
		@klass.class_eval "class << self; attr_reader :#{name}; end"

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
		else
		    @klass.instance_variable_get(:@elements).push element
		end
	    end
# @endgroup
	end
    end
end