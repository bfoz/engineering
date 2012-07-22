require 'geometry'
require 'model'
require 'sketch'
require 'units'

module SketchUp
=begin
    Export to a Ruby script that can be executed by SketchUp to recreate the geometry
=end

    HEADER_LINES = [
	'model = Sketchup.active_model',
	'model.entities.clear!',
	'model.definitions.purge_unused',
    ]

    SKETCHUP_UNITS = {
	'kilometer' => 'km',    'meter' => 'm',	    'centimeter'=> 'cm',    'millimeter'=> 'mm',
	'mile'	    => 'mile',	'yard'  => 'yard',  'feet'	=> 'feet',  'inch'	=> 'inch',
	'radian'    => 'radians',
	'degrees'   => 'degrees',
    }

    class Builder
	attr_accessor :container

	# Initialize with a Sketch or a Model
	def initialize(container=nil)
	    @container = container
	end

	def to_a
	    HEADER_LINES + to_array(@container)
	end

	def to_s
	    to_a.join "\n"
	end

	private

	# Convert the given container to an array of strings that SketchUp can read
	def to_array(container, parent='model.entities')
	    case container
		when Model
		    container.elements.map {|element| to_array(element) }.flatten
		when Model::Extrusion
		    if container.transformation and not container.transformation.identity?
			name = container.class.to_s + to_sketchup(container.length)
			lines = to_array(container.sketch, 'd.entities').map {|l| "#{l}.reverse!.pushpull(#{to_sketchup(container.length)})"}
			elements = [lines.flatten, "#{parent}.add_instance(d, #{to_sketchup(container.transformation)})"].join("\n\t")
			"lambda {|d|\n\t#{elements}\n}.call(model.definitions.add('#{name}'))"
		    else
			to_array(container.sketch, parent).map {|l| "#{l}.reverse!.pushpull(#{to_sketchup(container.length)})"}
		    end
		when Sketch
		    container.geometry.map {|element| to_sketchup(element, parent) }
	    end
	end

	# Convert the given entity to a string that SketchUp can read
	def to_sketchup(entity, parent='model.entities')
	    case entity
		when Array
		    entity.map {|v| to_sketchup(v) }.join(', ')
		when Geometry::Circle
		    "lambda{points = #{parent}.add_circle(#{to_sketchup(entity.center)}, [0,0,1], #{to_sketchup(entity.radius)}); points[0].find_faces; points[0].faces[0]}.call"
		when Geometry::Line
		    "#{parent}.add_line(#{to_sketchup(entity.first)}, #{to_sketchup(entity.last)})"
		when Geometry::Point
		    '[' + to_sketchup(entity.to_a) + ']'
		when Geometry::Polygon
		    "#{parent}.add_face(#{to_sketchup(entity.points)})"
		when Geometry::Rectangle
		    "#{parent}.add_face(#{to_sketchup(entity.points)})"
		when Geometry::Transformation
		    pt = entity.translation ? to_sketchup(entity.translation) : ''
		    "Geom::Transformation.new(#{pt})"
		when Rational
		    if entity.respond_to?(:units)
			[entity.to_f.to_s, to_sketchup(entity.units)].join '.'
		    else
			entity.to_f.to_s
		    end
		when Units
		    s = entity.to_s
		    SKETCHUP_UNITS[s] or raise "SketchUp won't recognize '#{s}'"
		when Units::Literal
		    [to_sketchup(entity.value), to_sketchup(entity.units)].join '.'
		else
		    entity.to_s
	    end
	end
    end

    def self.write(filename, container)
	File.write(filename, Builder.new(container).to_s)
    end
end
