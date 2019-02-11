# frozen_string_literal: true

require 'rake'
require 'rspec/core'
require 'rspec/core/rake_task'

desc 'runs all the specs'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = Dir.glob('spec/**/*_spec.rb')
  t.rspec_opts = '--format progress --fail-fast'
end
