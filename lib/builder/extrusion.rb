require 'model/extrusion'

require_relative 'sketch'

module Engineering
    module Builder
	# Build an {Extrusion} subclass
	class Extrusion
	    include ::Sketch::DSL

	    # Convenience method for creating a new builder and evaluating a block
	    def self.build(&block)
		self.new.build(&block)
	    end

	    def initialize
		@attribute_defaults = {}
	    end

	    # Evaluate a block in the context of an {Extrusion} and a {Skecth}
	    #  Use the trick found here http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	    #  to allow the DSL block to call methods in the enclosing *lexical* scope
	    def build(&block)
		@klass = Class.new(::Model::Extrusion)
		@sketch_klass = Class.new(::Sketch)

		@klass.singleton_class.send :attr_accessor, :sketch
		@klass.instance_variable_set('@sketch', @sketch_klass)

		if block_given?
		    # So that #push has something to append to
		    @sketch_klass.singleton_class.send :attr_accessor, :elements
		    @sketch_klass.instance_variable_set('@elements', [])

		    @self_before_instance_eval = block.binding.eval('self')
		    self.instance_eval(&block)

		    # Instance variable values for read-only attributes need special handling
		    setter_defaults = @attribute_defaults.select {|k,v| @sketch_klass.respond_to? k.to_s + '=' } # Find the ones that can be set normally
		    instance_variable_defaults = @attribute_defaults.reject {|k,v| @sketch_klass.respond_to? k.to_s + '=' }	# These must be set directly

		    # The new Sketch subclass needs an initializer too
		    @sketch_klass.send :define_method, :initialize do |*args, &block|
			# Directly set the read-only instance variables
			instance_variable_defaults.each {|k,v| instance_variable_set('@' + k.to_s, v) }

			super(*args, &block)

			# Push the default geometry
			self.class.instance_variable_get(:@elements).each do |a|
			    if a.is_a? Array
				push a.first.new(*a.last)
			    else
				push a
			    end
			end
		    end

		    @klass.send :define_method, :initialize do |options={}, &block|
			raise ArgumentError, "Can't initialize with a length when #{self} already has a length attribute" if self.class.length and options.key?(:length)
			raise ArgumentError, "Can't initialize with a Sketch when #{self} already has a Sketch attribute" if self.class.sketch and options.key?(:sketch)

			# Sketch doesn't support any Transformation options
			sketch_options = options.reject {|k,v| [:angle, :origin, :translate, :x, :y].include? k }
			# More things that Sketch can't handle
			sketch_options.reject! {|k,v| [:length, :sketch].include? k }

			# Evaluate any blocks in the passed arguments and dupe the options
			#  hash as a side effect so that the caller's hash isn't mutated
			options = (options.map {|k,v| { k => (v.respond_to?(:call) ? v.call : v) } }).reduce(:merge) || {}

			# Create a new instance of the Sketch subclass
			options[:sketch] = self.class.sketch.new(setter_defaults.merge(sketch_options)) if self.class.sketch
			options[:length] = self.class.length if self.class.length

			super options
		    end
		end

		@klass.singleton_class.send :attr_accessor, :length
		@klass.instance_variable_set('@length', @length)

		@klass
	    end

	    # The second half of the instance_eval delegation trick mentioned at
	    #   http://www.dan-manges.com/blog/ruby-dsls-instance-eval-with-delegation
	    def method_missing(method, *args, &block)
		if @klass.respond_to? method
		    @klass.send method, *args, &block
		elsif @sketch_klass.respond_to? method
		    @sketch_klass.send method, *args, &block
		else
		    @self_before_instance_eval.send method, *args, &block
		end
	    end

# @group DSL support methods

private

	    # Set the length attribute of the {Extrusion}
	    # @param length [Number]	the new length
	    def length(length=nil)
		@length = length if length
		@length
	    end

	    # Create a {Group} with an optional transformation
	    def build_group(*args, &block)
		[Builder::Sketch.new.build(::Sketch::Group, &block), args]
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
		name = name.to_sym

		# Class accessor that forwards to the Sketch
		@klass.class_eval "class << self; def #{name}; sketch.#{name}; end; end"

		# Instance accessor that forwards to the Sketch
		@klass.send :define_method, name.to_sym do
		    sketch.send name
		end

		# Instance accessor on the new Sketch
		@sketch_klass.send :attr_reader, name

		if value || block_given?
		    # Class accessor on the new Sketch subclass
		    @sketch_klass.singleton_class.send :attr_reader, name

		    # Set the ivar on the Sketch subclass
		    @sketch_klass.instance_variable_set('@' + name.to_s, value || instance_eval(&block))
		    @attribute_defaults[name] = value || block
		end
	    end

	    # Define an attribute with the given name
	    # @param name [String,Symbol]   the name of the attribute
	    def define_attribute_writer(name)
		method_name = name.to_s + '='

		# Class accessor that forwards to the Sketch
		@klass.class_eval "class << self; def #{method_name}(value); sketch.#{method_name} value; end; end"

		# Instance accessor that forwards to the Sketch
		@klass.send :define_method, method_name.to_sym do |value|
		    sketch.send method_name, value
		end

		# Instance accessor on the new Sketch
		@sketch_klass.send :attr_writer, name.to_sym
	    end

	    # Append a new object (with optional transformation) to the {Sketch}
	    def push(element, *args)
		if element.is_a? Class
		    @sketch_klass.instance_variable_get(:@elements).push [element, args]
		else
		    @sketch_klass.instance_variable_get(:@elements).push element
		end
	    end
# @endgroup
	end
    end
end