Gem::Specification.new do |s|
  s.name = %q{base4r}
  s.version = "0.2.0.6"
 
  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Dukeson, Blythe Dunham"]
  s.date = %q{2009-07-20}
  s.description = %q{Ruby client for the Google Base API}
  s.email = %q{blythe@snowgiraffe.com}
  s.files = Dir.glob(['lib/*.rb', 'test/*.rb', 'cert/cacert.pem', 'LICENSE', 'README'])
  s.has_rdoc = false
  s.homepage = %q{http://github.com/blythedunham/base4r}
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{base4r}
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Ruby client for the Google Base API}
  s.test_files = Dir.glob("test/*.rb")
  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2
 
    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end