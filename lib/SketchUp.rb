require 'geometry'
require 'sketch'

module SketchUp
=begin
    Export to a Ruby script that can be executed by SketchUp to recreate the geometry
=end
    
    class Builder
	# Build a script from a Sketch
	def from_sketch(sketch)
	    lines = []
	    lines.push 'model = Sketchup.active_model'
	    lines.push 'model.entities.clear!'
	    lines.push 'model.definitions.purge_unused'

	    sketch.geometry.map do |element|
		case element
		    when Geometry::Line
			lines.push "model.entities.add_line #{element.first.to_a}, #{element.last.to_a}"
		    when Geometry::Polygon
			points = element.points.map {|point| "#{point.to_a}" }
			points = points.join ', '
			lines.push "model.entities.add_face #{points}"
		    when Geometry::Rectangle
			points = element.points.map {|point| "#{point.to_a}" }
			points = points.join ', '
			lines.push "model.entities.add_face #{points}"
		end
	    end

	    lines.join "\n"
	end
    end

    def self.write(filename, sketch)
	File.write(filename, Builder.new.from_sketch(sketch))
    end
end
