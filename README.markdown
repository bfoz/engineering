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
and can therefore be handled by the gem utility, but others must be installed
manually. The easiest option is to use [Bundler](http://gembundler.com/), but
*gem* can be used if you're willing to install the *units* gem manually.

### Using Bundler

Installing the *engineering* gem using bundler is very easy, although a little more involved than normal.

Start with the normal gem command:

    gem install engineering

Unfortunately, this will either fail, or it will grab the wrong version of the *units* gem. But, not to worry, we can use bundler to fix it:

    bundle install

And that's it. You're done. Get on with taking over the world already.

If you happen to be part of the 0.001% of Mad Engineers who don't already have bundler installed, it's very easy to get:

    gem install bundler

### Using Rubygems

Sadly, the *units* gem hosted on [Rubygems](http://rubygems.org) is a bit out-of-date, and generally not the gem we're looking for. So, after *gem* does its thing, we need to do a little cleanup.

Start with the normal gem command:

    gem install engineering

Then uninstall the bogus *units* gem:

    gem uninstall units

Clone the gem we're looking for:

    git clone git://github.com/bfoz/units.git

Install it:

    cd units && rake install

You do have [rake](http://rake.rubyforge.org/) installed, right? If not, do this before the previous step:

    gem install rake

And you should be good to go. If you made it through all of that, then I expect to hear about your machinations on the evening news any day now.

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
