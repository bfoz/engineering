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
	    klass = Class.new(Model::Extrusion)
	    klass.const_set(:INITIALIZER_BLOCK, block)
	    klass.class_eval %q[
		def initialize(*args)
		    super
		    Model::Extrusion::Builder.new(self).evaluate(&INITIALIZER_BLOCK)
		end
	    ]
	    symbol ? Object.const_set(symbol, klass) : klass
	end

	# Create a new {Model} subclass and initialize it with the given block
	# @param name [Symbol]	The name of the new {Model} subclass
	def model(name, &block)
	    klass = Class.new(Model)
	    builder = Model::Builder.new
	    builder.evaluate(&block) if block_given?
	    initial_elements = builder.elements

	    klass.send :define_method, :initialize do |*args, &block|
		super *args, &block
		initial_elements.each {|a| push a }
	    end

	    Object.const_set(name, klass)
	end

	# Create a new {Sketch} subclass and initialize it with the given block
	# @param [Symbol]   symbol  The name of the {Sketch} subclass
	def sketch(symbol=nil, &block)
	    klass = Class.new(Sketch)
	    klass.const_set(:INITIALIZER_BLOCK, block)
	    klass.class_eval %q[
		def initialize(*args)
		    super
		    Sketch::Builder.new(self).evaluate(&INITIALIZER_BLOCK)
		end
	    ]
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
