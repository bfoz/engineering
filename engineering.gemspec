# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
    s.name        = "engineering"
    s.version     = '0'
    s.authors     = ["Brandon Fosdick"]
    s.email       = ["bfoz@bfoz.net"]
    s.homepage    = "http://github.com/bfoz/engineering"
    s.summary     = %q{Mad Engineering, Ruby style}
    s.description = %q{Tools for Mad Engineers and those who want to be}

    s.rubyforge_project = "engineering"

    s.files         = `git ls-files`.split("\n")
    s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
    s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.require_paths = ["lib"]

    s.add_dependency	'dxf'
    s.add_dependency	'model'
    s.add_dependency	'sketch'
    s.add_dependency	'units', '>= 2'
end
