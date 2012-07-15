require 'minitest/autorun'
require 'sketchup'

describe SketchUp::Builder do
    before do
    	@builder = SketchUp::Builder.new
    end

    let(:header_lines)	    { SketchUp::HEADER_LINES }
    let(:empty_model_data)  { header_lines.join "\n" }
    let(:simple_extrusion_model_data)	{ header_lines.push('model.entities.add_face([-5.0, -10.0], [-5.0, 10.0], [5.0, 10.0], [5.0, -10.0]).reverse!.pushpull(5)').join "\n" }
    let(:simple_extrusion_units_model_data)	{ header_lines.push('model.entities.add_face([-0.5.m, -5.0], [-0.5.m, 5.0], [0.5.m, 5.0], [0.5.m, -5.0]).reverse!.pushpull(5.m)').join "\n" }

    let(:empty_sketch_data) { header_lines.join "\n" }
    let(:line_sketch_data)  { header_lines.push('model.entities.add_line([0, 0], [1, 0])').join "\n" }
    let(:rectangle_sketch_data)	{ header_lines.push('model.entities.add_face([0, 0], [0, 1], [1, 1], [1, 0])').join "\n" }

    it "should keep private methods private" do
	@builder.wont_respond_to :to_array
	@builder.wont_respond_to :to_sketchup
    end

    describe "when given an empty Model object" do
	before do
	    sketch = Sketch.new
	    model = Model.new
	    model.add_extrusion Model::Extrusion.new(5, sketch)
	    @builder.container = model
	end

	it "should export the correct file" do
	    @builder.to_s.must_equal empty_model_data
	end
    end

    it "should generate the correct text from a Model of a simple extrusion" do
	sketch = Sketch.new
	sketch.add_rectangle 10, 20
	model = Model.new do
	    add_extrusion Model::Extrusion.new(5, sketch)
	end
	@builder.container = model
	@builder.to_s.must_equal simple_extrusion_model_data
    end

    it "should generate the correct text from a Model of a simple extrusion with units" do
	sketch = Sketch.new
	sketch.add_rectangle 1.meter, 10
	model = Model.new
	model.add_extrusion Model::Extrusion.new(5.meters, sketch)
	@builder.container = model
	@builder.to_s.must_equal simple_extrusion_units_model_data
    end

    it "should not break Point's to_s method" do
	5.cm.to_s.must_equal "5"
    end

    it "should not break Point's inspect method" do
	5.cm.inspect.must_equal "5 centimeter"
    end

    it "should generate correct text from an empty Sketch" do
	@builder.container = Sketch.new
	@builder.to_s.must_equal empty_sketch_data
    end

    it "should generate correct text from a simple Sketch object" do
	sketch = Sketch.new
	sketch.add_line [0,0], [1,0]
	@builder.container = sketch
	@builder.to_s.must_equal line_sketch_data
    end

    it "should generate correct text from a Sketch object with a single Rectangle" do
	sketch = Sketch.new
	sketch.add_rectangle [0,0], [1,1]
	@builder.container = sketch
	@builder.to_s.must_equal rectangle_sketch_data
    end

    it "should generate correct text from a Sketch object with a single Polygon" do
	sketch = Sketch.new
	sketch.add_polygon [0,0], [0,1], [1,1], [1,0], [0,0]
	@builder.container = sketch
	@builder.to_s.must_equal rectangle_sketch_data
    end
end
