Engineering for Ruby
====================

This is a meta-gem for all things related to engineering (particularly CAD stuff). The Engineering module
is your one stop shop for all of the tools you need for your latest mad-engineering project.

Activating a dormant volcano? Adding death rays to your secret moon base? Plotting world domination? No problem! There's a gem for that, and you've found it right here.

If your latest and greatest project, and even your older ones, need something
that isn't in Engineering, either let me know, or fork and add it yourself (and
send me a pull request). Or feel free to create your own gem that reopens
the module and adds whatever is missing, if that's more your style.

License
-------

Copyright 2012-2013 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.

Dependencies
------------

- Units [GitHub](https://github.com/bfoz/units)
- Geometry [GitHub](https://github.com/bfoz/geometry) [RubyGems](https://rubygems.org/gems/geometry)
- Sketch [GitHub](https://github.com/bfoz/sketch)
- Model [GitHub](https://github.com/bfoz/model)

Installation
------------

Engineering has a number of dependencies. Some of which are hosted on rubygems.org
and can therefore be handled by the gem utility, but others must be installed manually.

Examples
--------

Creating a custom Cube class, the hard way:

    require 'engineering'

    model :MyCube do
        extrusion 10.cm do
            add_square 10.cm
        end
    end

    MyCube.new

Once a Model has been defined, it can be instantiated and exported to SketchUp with a single line

    SketchUp.write('MyCube.su', MyCube.new)

Then, launch SketchUp, open the _Ruby Console_ (it's in the Window menu), and _load 'MyCube.su'_. Your new geometry will replace whatever was already in the SketchUp document (a person if you just opened it), so be careful.
