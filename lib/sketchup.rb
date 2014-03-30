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
	    @definition_names = {}
	end

	def to_a
	    a = to_array(@container) || []	# Generates the definitions as a side effect
	    HEADER_LINES + @definition_names.values.flatten + a
	end

	def to_s
	    to_a.join("\n") << "\n"
	end

	private

	def name_for_container(container)
	    case container
		when Model::Extrusion
		    container.class.to_s +  "(#{name_for_container(container.sketch)})_#{to_sketchup(container.length)}"
		when Model::Group
		    container.class.to_s +  "(#{container.object_id.to_s})"
		when Model  # !!! Must be after all subclasses of Model
		    s = container.class.to_s
		    (s == 'Model') ? s + "(#{container.object_id.to_s})" : s
		when Sketch
		    s = container.class.to_s
		    (s == 'Sketch') ? s + ":#{container.object_id.to_s}" : s
	    end
	end

	def to_definition(container, definition_name)
	    case container
		when Model::Extrusion
		    lines = to_array(container.sketch, 'd.entities').map {|l| "#{l}.pushpull(#{to_sketchup(-container.length)})"}
		    elements = lines.flatten.join("\n\t")
		    "lambda {|d|\n\t#{elements}\n}.call(model.definitions.add('#{definition_name}'))"
		when Model::Group
		    lines = container.elements.map {|element| to_array(element, 'g.entities') }.flatten
		    elements = lines.flatten.join("\n\t")
		    "lambda {|g|\n\t#{elements}\n}.call(model.definitions.add('#{definition_name}'))"
		when Model  # !!! Must be after all subclasses of Model
		    elements = container.elements.map {|element| to_array(element, 'm.entities') }.flatten.join("\n\t")
		    "lambda {|m|\n\t#{elements}\n}.call(model.definitions.add('#{definition_name}'))"
	    end
	end

	def add_instance(parent, container)
	    definition_name = name_for_container(container)
	    unless @definition_names.key?(definition_name)
		@definition_names[definition_name] = to_definition(container, definition_name)
	    end
	    ["#{parent}.add_instance(model.definitions['#{definition_name}'], #{to_sketchup(container.transformation)})"]
	end

	# Convert the given container to an array of strings that SketchUp can read
	def to_array(container, parent='model.entities', transformation=nil)
	    case container
		when Model::Extrusion
		    if container.transformation and not container.transformation.identity?
			add_instance(parent, container)
		    else
			to_array(container.sketch, parent, container.transformation).map {|l| "#{l}.pushpull(#{to_sketchup(-container.length)})"}
		    end
		when Model::Group
		    if container.transformation and not container.transformation.identity?
			add_instance(parent, container)
		    else
			container.elements.map {|element| to_array(element, parent) }.flatten
		    end
		when Model  # !!! Must be after all subclasses of Model
		    if container.transformation and not container.transformation.identity?
			add_instance(parent, container)
		    else
			container.elements.map {|element| to_array(element, parent) }.flatten
		    end
		when Sketch::Group
		    container.geometry.map {|element| to_sketchup(element, parent, container.transformation) }.flatten
		when Sketch  # !!! Must be after all subclasses of Sketch
		    container.geometry.map do |element|
			case element
			    when Sketch::Group then to_array(element, parent)
			    else
				to_sketchup(element, parent, transformation)
			end
		    end.flatten
	    end
	end

	# Convert the given entity to a string that SketchUp can read
	# @return [String]
	def to_sketchup(entity, parent='model.entities', transformation=nil)
	    case entity
		when Array
		    entity.map {|v| to_sketchup(v, parent, transformation) }.join(', ')
		when Geometry::Arc
		    "#{parent}.add_arc(#{to_sketchup(entity.center)}, [1,0,0], [0,0,1], #{to_sketchup(entity.radius)}, #{to_sketchup(entity.start_angle)}, #{to_sketchup(entity.end_angle)})"
		when Geometry::Circle
		    "lambda{ points = #{parent}.add_circle(#{to_sketchup(entity.center, parent, transformation)}, [0,0,1], #{to_sketchup(entity.radius)}); points[0].find_faces; points[0].faces[0]}.call"
		when Geometry::Edge
		    "#{parent}.add_edges(#{to_sketchup(entity.first)}, #{to_sketchup(entity.last)})"
		when Geometry::Line
		    "#{parent}.add_line(#{to_sketchup(entity.first)}, #{to_sketchup(entity.last)})"
		when Geometry::Path
		    edges = entity.elements.map {|e| to_sketchup(e, parent, transformation) }.flatten.join '+'
		    "#{parent}.add_face(#{edges})"
		when Geometry::Polyline
		    vertices = entity.vertices.map {|v| to_sketchup(v, parent, transformation) }.join ', '
		    method = entity.is_a?(Geometry::Polygon) ? 'add_face' : 'add_curve'
		    "#{parent}.#{method}(#{vertices})"
		when Geometry::PointZero
		    to_sketchup(Point[0,0], parent, transformation)
		when Geometry::Point
		    if transformation and not transformation.identity?
			'Geom::Point3d.new(' + to_sketchup(entity.to_a) + ').transform!(' + to_sketchup(transformation) + ')'
		    else
			'[' + to_sketchup(entity.to_a) + ']'
		    end
		when Geometry::Polygon
		    "#{parent}.add_face(#{to_sketchup(entity.points, parent, transformation)})"
		when Geometry::Rectangle, Geometry::Square
		    "#{parent}.add_face(#{to_sketchup(entity.points, parent, transformation)})"
		when Geometry::Transformation
		    pt = '[' + (entity.translation ? to_sketchup(entity.translation.to_a) : '0,0,0') + ']'
		    x_axis = '[' + ((entity.rotation && entity.rotation.x) ? to_sketchup(entity.rotation.x.to_a) : '1,0,0') + ']'
		    y_axis = '[' + ((entity.rotation && entity.rotation.y) ? to_sketchup(entity.rotation.y.to_a) : '0,1,0') + ']'
		    "Geom::Transformation.new(#{[pt,x_axis,y_axis].join(',')})"
		when Geometry::Triangle
		    "#{parent}.add_face(#{to_sketchup(entity.points, parent, transformation)})"
		when Float
		    entity.to_s
		when Rational
		    [entity.to_f, entity.respond_to?(:units) ? entity.units : nil].compact.map {|a| to_sketchup(a)}.join '.'
		when Units
		    s = entity.to_s
		    SKETCHUP_UNITS[s] or raise "SketchUp won't recognize '#{s}'"
		when Units::Operator
		    operator =	case entity
				    when Units::Addition then ' + '
				    when Units::Division then ' / '
				    when Units::Subtraction then ' - '
				end
		    '(' + entity.operands.map {|a| to_sketchup(a)}.join(operator) + ')'
		when Units::Numeric
		    [entity.value, entity.units].compact.map {|a| to_sketchup(a)}.join '.'
		else
		    entity.to_s
	    end
	end
    end

    def self.write(filename, container)
	File.write(filename, Builder.new(container).to_s)
    end
end
