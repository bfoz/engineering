require 'geometry'
require 'model'
require 'sketch'

module SketchUp
=begin
    Export to a Ruby script that can be executed by SketchUp to recreate the geometry
=end

    class Builder
	# Build a script from a Model
	def from_model(model)
	    lines = header_lines

	    model.elements.map do |element|
		case element
		    when Model::Extrusion
			lines += sketch_lines(element.sketch).map {|l| "#{l}.reverse!.pushpull(#{element.length})"}
		end
	    end

	    lines.join "\n"
	end

	# Build a script from a Sketch
	def from_sketch(sketch)
	    lines = header_lines + sketch_lines(sketch)
	    lines.join "\n"
	end

	private

	def header_lines
	    ['model = Sketchup.active_model',
	     'model.entities.clear!',
	     'model.definitions.purge_unused',
	    ]
	end

	def sketch_lines(sketch)
	    sketch.geometry.map do |element|
		case element
		    when Geometry::Circle
			"lambda{points = model.entities.add_circle(#{element.center.to_a}, [0,0,1], #{element.radius}); points[0].find_faces; points[0].faces[0]}.call"
		    when Geometry::Line
			"model.entities.add_line(#{element.first.to_a}, #{element.last.to_a})"
		    when Geometry::Polygon
			points = element.points.map {|point| "#{point.to_a}" }
			points = points.join ', '
			"model.entities.add_face(#{points})"
		    when Geometry::Rectangle
			points = element.points.map {|point| "#{point.to_a}" }
			points = points.join ', '
			"model.entities.add_face(#{points})"
		end
	    end
	end
    end

    def self.write(filename, sketch)
	case sketch
	    when Sketch
		File.write(filename, Builder.new.from_sketch(sketch))
	    when Model
		File.write(filename, Builder.new.from_model(sketch))
	end
    end
end
