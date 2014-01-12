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
	# @param [Symbol] symbol    The name of the resulting subclass
	# @return [Extrusion]
	def extrusion(symbol=nil, &block)
	    builder = Model::Extrusion::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_arguments = {sketch: builder.extrusion.sketch, length: builder.extrusion.length}.select {|k,v| v }

	    klass = Class.new(Model::Extrusion)
	    klass.send :define_method, :initialize do |options={}, &block|
		super initial_arguments.merge(options), &block
	    end

	    symbol ? Object.const_set(symbol, klass) : klass
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
	    attribute_getters.each {|k, m| klass.send :define_method, k, m }

	    attribute_setters = builder.instance_variable_get(:@attribute_setters) || {}
	    attribute_setters.each {|k, m| klass.send :define_method, k, m }

	    klass.send :define_method, :initialize do |*args, &block|
		super *(attribute_defaults.map {|k,v| { k => (v.respond_to?(:call) ? v.call : v) } }), *args, &block
		initial_elements.each {|a| push a }
	    end

	    Object.const_set(name, klass)
	end

	# Create a new {Sketch} subclass and initialize it with the given block
	# @param [Symbol]   symbol  The name of the {Sketch} subclass
	def sketch(symbol=nil, &block)
	    builder = Sketch::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_elements = builder.elements

	    klass = Class.new(Sketch)
	    klass.send :define_method, :initialize do |*args, &block|
		super *args, &block
		initial_elements.each {|a| push a }
	    end

	    symbol ? Object.const_set(symbol, klass) : klass
	end

	class Geometry::Polygon
	    # Build a {Polygon} instance using the {Sketch} DSL
	    # @return [Polygon]
	    def self.build(&block)
		Sketch::PolygonBuilder.new.evaluate(&block)
	    end
	end

	class Geometry::Polyline
	    # Build a {Polyline} instance using the {Sketch} DSL
	    # @return [Polyline]
	    def self.build(&block)
		Sketch::PolylineBuilder.new.evaluate(&block)
	    end
	end
    end
end

self.extend Engineering::DSL
include Geometry	# Make Geometry types more readily available
