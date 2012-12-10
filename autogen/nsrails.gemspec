# coding: utf-8
Gem::Specification.new do |s|
  s.name = %q{nsrails}
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Hassin", "Jason Lee"]
  s.email = %q{huacnlee@gmail.com}
	s.files = Dir['readme.md', 'bin/**/*', 'lib/**/{*,.[a-z]*}']
  s.bindir      = 'bin'
  s.executables = ['nsrails']
  s.homepage = %q{https://github.com/huacnlee/rails-settings-cached}
  s.require_paths = ["lib"]
  s.summary = %q{NSRails is a light-weight Objective-C framework that provides your classes with a high-level, ActiveResource-like API. This means CRUD and other operations on your corresponding Rails objects can be called natively via Objective-C methods.}
  
  s.add_dependency 'activesupport', "> 3.0.0"
end

