require 'minitest/autorun'
require 'sketchup'

describe SketchUp::Builder do
    Size = Geometry::Size

    subject { SketchUp::Builder.new }

    before do
    	@builder = SketchUp::Builder.new
    end

    let(:empty_fixture)		    { File.read('test/fixtures/sketchup/empty.su') }
    let(:rectangle_sketch_fixture)  { File.read('test/fixtures/sketchup/rectangle_sketch.su') }

    it "should keep private methods private" do
	@builder.wont_respond_to :to_array
	@builder.wont_respond_to :to_sketchup
    end

    it "should not break Point's to_s method" do
	5.cm.to_s.must_equal "5"
    end

    it "should not break Point's inspect method" do
	5.cm.inspect.must_equal "5 centimeter"
    end

    describe "when given an empty Model object" do
	before do
	    model = Model.new
	    model.push Model::Extrusion.new(length:5, sketch:Sketch.new)
	    @builder.container = model
	end

	it "should export the correct file" do
	    @builder.to_s.must_equal empty_fixture
	end
    end

    describe "when given a Model of a translated Extrusion" do
	sketch = Sketch.new
	sketch.push Geometry::Rectangle.new size:[10, 20]
	before do
	    subject.container = Model.new do
		push Model::Extrusion.new(length:5, sketch:sketch, transformation:Geometry::Transformation.new(origin:[1,2,3]))
	    end
	end

	it "must generate the correct text" do
	    subject.to_s.must_match Regexp.new(File.read('test/fixtures/translated_extrusion.su'))
	end
    end

    it "should generate the correct text from a Model of a simple extrusion" do
	sketch = Sketch.new
	sketch.push Geometry::Rectangle.new size:[10, 20]
	model = Model.new do
	    push Model::Extrusion.new(length:5, sketch:sketch)
	end
	@builder.container = model
	@builder.to_s.must_equal File.read('test/fixtures/sketchup/simple_extrusion.su')
    end

    it "should generate the correct text from a Model of a simple extrusion with units" do
	sketch = Sketch.new
	sketch.push Geometry::Rectangle.new size:[1.meter, 10]
	model = Model.new
	model.push Model::Extrusion.new(length:5.meters, sketch:sketch)
	@builder.container = model
	@builder.to_s.must_equal File.read('test/fixtures/sketchup/simple_extrusion_units.su')
    end

    it "should generate correct text from an empty Sketch" do
	@builder.container = Sketch.new
	@builder.to_s.must_equal empty_fixture
    end

    it "should generate correct text from a simple Sketch object" do
	sketch = Sketch.new
	sketch.push Geometry::Line[[0,0], [1,0]]
	@builder.container = sketch
	@builder.to_s.must_equal File.read('test/fixtures/sketchup/line_sketch.su')
    end

    describe "when given a Sketch" do
	it "must RegularPolygon" do
	    subject.container = Sketch.new.tap {|s| s.push RegularPolygon.new(sides:6, center:[0,0], radius:5) }
	    subject.to_s.must_equal File.read('test/fixtures/sketchup/hexagon_sketch.su')
	end
    end

    it "should generate correct text from a Sketch object with a single Rectangle" do
	sketch = Sketch.new
	sketch.push Geometry::Rectangle.new origin:[0,0], size:[1,1]
	@builder.container = sketch
	@builder.to_s.must_equal rectangle_sketch_fixture
    end

    it "should generate correct text from a Sketch object with a single Polygon" do
	sketch = Sketch.new
	sketch.push Polygon.new [0,0], [0,1], [1,1], [1,0], [0,0]
	@builder.container = sketch
	@builder.to_s.must_equal rectangle_sketch_fixture
    end

    it "must handle a Group" do
	builder = SketchUp::Builder.new( Model::Builder.new.evaluate { group :origin => [1,2,3] })
	builder.container.elements.count.must_equal 1
	builder.container.elements.first.must_be_instance_of(Model::Group)
	builder.to_s.must_match %r{model = Sketchup.active_model\nmodel.entities.clear!\nmodel.definitions.purge_unused\nlambda {|g|\n\t\n}.call(model.definitions.add('Model::Group()'))\nmodel.entities.add_instance(model.definitions\['Model::Group(\d+)'\], Geom::Transformation.new(\[1, 2, 3\],\[1,0,0\],\[0,1,0\]))}
    end

    it "must handle a sub-model" do
	builder = SketchUp::Builder.new( Model::Builder.new.evaluate { push Model.new, :origin => [3,2,1] })
	builder.container.elements.first.must_be_instance_of(Model)
	builder.to_s.must_match %r{model = Sketchup.active_model\nmodel.entities.clear!\nmodel.definitions.purge_unused\nlambda {|m|\n\t\n}.call(model.definitions.add('Model(\d+)'))\nmodel.entities.add_instance(model.definitions\['Model(\d+)'\], Geom::Transformation.new(\[3, 2, 1\],\[1,0,0\],\[0,1,0\]))}
    end

    describe "when unparsing a Sketch" do
	describe "when the Sketch has a Group" do
	    before do
		builder = Sketch::Builder.new
		builder.group origin:[1,2] { circle diameter:1 }
		subject.container = builder.sketch
	    end

	    it "must generate the correct text" do
		subject.to_s.must_equal File.read('test/fixtures/sketchup/sketch_group.su')
	    end

	    describe 'when the Group contains a Group' do
		before do
		    subject.container = Sketch::Builder.new do
			group origin:[1,2] do
			    group origin:[3,4] do
				circle diameter:1
			    end
			end
		    end.sketch
		end

		it 'must generate the correct text' do
		    subject.to_s.must_equal File.read('test/fixtures/sketchup/sketch_group_group.su')
		end
	    end

	    describe 'when the Group contains a Group with a Group' do
		before do
		    subject.container = Sketch::Builder.new do
			group origin:[1,2] do
			    group origin:[3,4] do
				group origin:[5,6] do
				    circle diameter:1
				end
			    end
			end
		    end.sketch
		end

		it 'must generate the correct text' do
		    subject.to_s.must_equal File.read('test/fixtures/sketchup/sketch_group_group_group.su')
		end
	    end
	end
    end

    it "Path" do
	sketch = Sketch.new
	sketch.push Path.new [0,0], Geometry::Arc.new(center:[0,0], radius:5, start:0, end:90*Math::PI/180), [0,0]
	builder = SketchUp::Builder.new( Model::Builder.new.evaluate { extrude length:5, sketch:sketch })
    end
end
