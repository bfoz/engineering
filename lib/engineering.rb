require 'mathn'

require 'dxf'
require 'model'
require 'sketch'
require 'units'

require_relative 'sketchup'

=begin
A meta-gem for wayward engineering-related gems. Here you can find everything 
you'll need for your latest engineering project.
=end

module Engineering
    module DSL
	private

	# Create a new {Extrusion} subclass and initialize it with the given block
	# @param name [Symbol]    The name of the resulting subclass
	def extrusion(symbol, &block)
	    builder = Model::Extrusion::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_arguments = {sketch: builder.extrusion.sketch, length: builder.extrusion.length}.select {|k,v| v }

	    klass = Class.new(Model::Extrusion)

	    if initial_arguments.has_key?(:length)
		klass.instance_variable_set :@length, initial_arguments[:length]
		klass.class.send(:define_method, :length) { @length }
	    end

	    klass.instance_variable_set :@sketch, initial_arguments[:sketch]
	    klass.class.send(:define_method, :sketch) { @sketch }

	    klass.send :define_method, :initialize do |options={}, &block|
		raise ArgumentError, "Can't initialize with a length when #{self} already has a length attribute" if initial_arguments.has_key?(:length) and options.has_key?(:length)
		super initial_arguments.merge(options), &block
	    end

	    Object.const_set(symbol, klass)
	end

	# Create a new {Model} subclass and initialize it with the given block
	# @param name [Symbol]	The name of the new {Model} subclass
	def model(name, &block)
	    klass = Class.new(Model)
	    builder = Model::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_elements = builder.elements

	    # The defaults are hidden in an instance variable so that the passed block can't accidentally corrupt them
	    attribute_defaults = builder.instance_variable_get(:@attribute_defaults) || {}

	    # Bind any attribute getters and setters to the new subclass
	    attribute_getters = builder.instance_variable_get(:@attribute_getters) || {}
	    attribute_getters.each do |k, m|
		klass.send :define_method, k, m
		if attribute_defaults.has_key?(k)
		    klass.instance_variable_set('@' + k.to_s, attribute_defaults[k])
		    klass.class.send(:define_method, k) { instance_variable_get('@' + k.to_s) }
		end
	    end

	    attribute_setters = builder.instance_variable_get(:@attribute_setters) || {}
	    attribute_setters.each {|k, m| klass.send :define_method, k, m }

	    # Instance variable values for read-only attributes need special handling
	    options = attribute_defaults.select {|k,v| klass.respond_to? k.to_s + '=' }
	    instance_variable_defaults = attribute_defaults.reject {|k,v| klass.respond_to? k.to_s + '=' }
	    klass.send :define_method, :initialize do |*args, &block|
		instance_variable_defaults.each {|k,v| instance_variable_set('@' + k.to_s, v) }
		super *(options.map {|k,v| { k => (v.respond_to?(:call) ? v.call : v) } }), *args, &block
		initial_elements.each {|a| push a }
	    end

	    Object.const_set(name, klass)
	end

	# Create a new {Sketch} subclass and initialize it with the given block
	# @param name [Symbol]  The name of the {Sketch} subclass
	def sketch(symbol, &block)
	    builder = Sketch::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_elements = builder.elements

	    klass = Class.new(Sketch)
	    klass.send :define_method, :initialize do |*args, &block|
		super *args, &block
		initial_elements.each {|a| push a }
	    end

	    Object.const_set(symbol, klass)
	end

	class Geometry::Polygon
	    # Build a {Polygon} instance using the {Sketch} DSL
	    # @return [Polygon]
	    def self.build(&block)
		Sketch::Builder::Polygon.new.evaluate(&block)
	    end
	end

	class Geometry::Polyline
	    # Build a {Polyline} instance using the {Sketch} DSL
	    # @return [Polyline]
	    def self.build(&block)
		Sketch::Builder::Polyline.new.evaluate(&block)
	    end
	end
    end
end

self.extend Engineering::DSL
include Geometry	# Make Geometry types more readily available
