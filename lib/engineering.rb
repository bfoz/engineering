require 'mathn'

require 'dxf'
require 'model'
require 'sketch'
require 'units'

require_relative 'builder/extrusion'
require_relative 'builder/model'
require_relative 'builder/sketch'
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
	def extrusion(name=nil, &block)
	    klass = Engineering::Builder::Extrusion.build(&block)
	    if name
		parent = (Module == self.class) ? self : Object
		parent.const_set(name, klass)
	    end
	    klass
	end

	# Create a new {Model} subclass and initialize it with the given block
	# @param name [Symbol]	The name of the new {Model} subclass
	def model(name=nil, &block)
	    klass = Builder::Model.build(&block)
	    if name
		parent = (Module == self.class) ? self : Object
		parent.const_set(name, klass)
	    end
	    klass
	end

	# Create a new {Sketch} subclass and initialize it with the given block
	# @param name [Symbol]  The name of the {Sketch} subclass
	def sketch(name=nil, &block)
	    klass = Builder::Sketch.build(&block)
	    if name
		parent = (Module == self.class) ? self : Object
		parent.const_set(name, klass)
	    end
	    klass
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

# Allow the DSL to be called from within Module definitions
class Module
    include Engineering::DSL
end
