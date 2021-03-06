# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{inline_uploader}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Matt Freels"]
  s.date = %q{2009-10-10}
  s.description = %q{Provides an upload endpoint for ajax uploads and easy attachement of ajax uploads as POST params for normal requests.}
  s.email = %q{matt@freels.name}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "examples/uploader/public/ajaxfileupload.js",
     "examples/uploader/uploader.rb",
     "inline_uploader.gemspec",
     "lib/inline_uploader.rb",
     "test/inline_uploader_test.rb",
     "test/test_helper.rb"
  ]
  s.homepage = %q{http://github.com/freels/inline_uploader}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{rack endpoint and handler for ajax uploads}
  s.test_files = [
    "test/inline_uploader_test.rb",
     "test/test_helper.rb",
     "examples/uploader/uploader.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
