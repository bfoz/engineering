require 'geometry'
require 'model'
require 'sketch'
require 'units'

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

	SKETCHUP_UNITS = {
	    'kilometer' => 'km',    'meter' => 'm',	'centimeter'=> 'cm',	'millimeter'=> 'mm',
	    'mile'	=> 'mile',  'yard'  => 'yard',	'feet'	    => 'feet',	'inch'	    => 'inch',
	    'radian'	=> 'radians',
	    'degrees'	=> 'degrees',
	}

	# Convert the given entity to a line of text that SketchUp can read
	def to_sketchup(entity)
	    case entity
		when Array
		    entity.map {|v| to_sketchup(v) }.join(', ')
		when Geometry::Point
		    '[' + entity.to_a.map {|v| to_sketchup(v) }.join(', ') + ']'
		when Units
		    s = entity.to_s
		    if SKETCHUP_UNITS.key?(s)
			SKETCHUP_UNITS[s]
		    else
			raise "SketchUp won't recognize '#{s}'"
		    end
		when Units::Literal
		    entity.to_s + (entity.units ? '.' + to_sketchup(entity.units) : '')
		else
		    entity.to_s
	    end
	end

	def sketch_lines(sketch)
	    sketch.geometry.map do |element|
		case element
		    when Geometry::Circle
			"lambda{points = model.entities.add_circle(#{to_sketchup(element.center)}, [0,0,1], #{to_sketchup(element.radius)}); points[0].find_faces; points[0].faces[0]}.call"
		    when Geometry::Line
			"model.entities.add_line(#{to_sketchup(element.first)}, #{to_sketchup(element.last)})"
		    when Geometry::Polygon
			"model.entities.add_face(#{to_sketchup(element.points)})"
		    when Geometry::Rectangle
			"model.entities.add_face(#{to_sketchup(element.points)})"
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
