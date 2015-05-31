Engineering for Ruby
====================

[![Build Status](https://travis-ci.org/bfoz/engineering.svg?branch=master)](https://travis-ci.org/bfoz/engineering)
[![Gem Version](https://badge.fury.io/rb/engineering.svg)](http://badge.fury.io/rb/engineering)

This is a meta-gem for all things related to engineering (particularly CAD stuff). The Engineering module
is your one stop shop for all of the tools you need for your latest mad-engineering project.

Activating a dormant volcano? Adding death rays to your secret moon base? Plotting world domination? No problem! There's a gem for that, and you've found it right here.

If your latest and greatest project, and even your older ones, need something
that isn't in Engineering, either let me know, or fork and add it yourself (and
send me a pull request). Or feel free to create your own gem that reopens
the module and adds whatever is missing, if that's more your style.

Dependencies
------------

- DXF [GitHub](http://github.com/bfoz/ruby-dxf) [RubyGems](https://rubygems.org/gems/dxf)
- Units [GitHub](https://github.com/bfoz/units-ruby)
- Geometry [GitHub](https://github.com/bfoz/geometry) [RubyGems](https://rubygems.org/gems/geometry)
- Sketch [GitHub](https://github.com/bfoz/sketch)
- Model [GitHub](https://github.com/bfoz/model)

Installation
------------

_Engineering_ has a number of dependencies. Some of which are hosted on [RubyGems](https://rubygems.org)
and can be handled by the `gem` utility, but others must be installed manually.

The *units* gem hosted on [Rubygems](http://rubygems.org) is a bit out-of-date, and generally not the gem we're looking for. So, before installing the *engineering* gem, we need to manually install the correct *units* gem.

First, make sure you don't already have a conflicting version of *units*:

    gem uninstall units

Next, clone the gem that we're looking for:

    git clone git://github.com/bfoz/units.git

You probably already have [rake](http://rake.rubyforge.org/) installed, but if you don't, then do this before going any further:

    gem install rake

Finally, install the correct *units* gem:

    cd units && rake install

Now, we can install *engineering* in the normal fashion:

    gem install engineering

And that's it. You're done. Get going with taking over the world already.

Examples
--------

Creating a custom Cube class, the hard way:

    require 'engineering'

    model :MyCube do
        extrusion 10.cm do
            square 10.cm
        end
    end

    MyCube.new

Of course, this is ruby, so there's always another way to do it

    extrusion :MyCube do
        rectangle Size[10.cm, 10.cm]
    end

    MyCube.new length:10.cm

### Attributes

Models can have attributes that stand-in for values that aren't known until the subclass is instantiated.

```ruby
model :VariableCube do
    attribute :side_length

    extrusion side_length do
        square side_length
    end
end
```

Given the above, you can then make cubes of any size you like.

```ruby
small_cube = VariableCube.new(side_length:1.cm)
large_cube = VariableCube.new(side_length:1.km)
```

You can also give the attributes values right away, and then use them as properties when defining other geometry.

```ruby
model :SugarCube do
    attribute side_length: 1.cm

    extrusion side_length do
       square side_length
    end
end

# Stack the cubes
bottom_cube = SugarCube.new
top_cube = SugarCube.new(origin:[0,0,SugarCube.side_length])
```

### Exporting

Once a Model has been defined, it can be instantiated and exported to SketchUp with a single line

    SketchUp.write('MyCube.su', MyCube.new)

Then, launch SketchUp, open the _Ruby Console_ (it's in the Window menu), and _load 'MyCube.su'_. Your new geometry will replace whatever was already in the SketchUp document (a person if you just opened it), so be careful.

License
-------

Copyright 2012-2015 by [Brandon Fosdick](bfoz@bfoz.net) and released under the [BSD license](http://opensource.org/licenses/BSD-2-Clause).
