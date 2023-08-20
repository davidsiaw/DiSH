# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dishiz/version'

Gem::Specification.new do |spec|
  unless spec.respond_to?(:metadata)
    # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host',
    # or delete this section to allow pushing this gem to any host.
    raise <<-ERR
      RubyGems 2.0 or newer is required to protect against public gem pushes.
    ERR
  end

  spec.name          = 'dishiz'
  spec.version       = Dishiz::VERSION
  spec.authors       = ['David Siaw']
  spec.email         = ['davidsiaw@gmail.com']

  spec.summary       = 'Digital Sim with Hi-Z'
  spec.description   = 'Digital Sim with Hi-Z'
  spec.homepage      = 'https://github.com/davidsiaw/dishiz'
  spec.license       = 'MIT'

  spec.files         = Dir['{data,exe,lib,bin}/**/*'] + %w[Gemfile dishiz.gemspec]
  spec.test_files    = Dir['{test,spec,features}/**/*']
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'require_all'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
end
