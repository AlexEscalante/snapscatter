# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snapscatter/version'

Gem::Specification.new do |spec|
  spec.name          = "snapscatter"
  spec.version       = Snapscatter::VERSION
  spec.authors       = ["Alex Escalante"]
  spec.email         = ["alex.escalante@gmail.com"]
  spec.description   = %q{Geographically distributed and consistent AWS snapshots}
  spec.summary       = %q{Creates consistent snapshots from EBS volumes and copies them across regions for disaster recovery}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "mongo"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "cucumber"
  spec.add_development_dependency "aruba"
end
