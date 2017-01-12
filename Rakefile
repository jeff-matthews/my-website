require 'rubocop/rake_task'
require 'rspec/core/rake_task'
require 'rake/testtask'
require 'coveralls/rake/task'

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['-crubocop.yaml']
end

Coveralls::RakeTask.new

Rake::TestTask.new(:test_all) do |t|
  t.test_files = Dir['test/**/*_spec.rb'] + Dir['test/**/test_*.rb']
  t.libs << 'test'
end

RSpec::Core::RakeTask.new(:spec)

task test: [:spec, :test_all, :rubocop]
task test_ci: [:test, :'coveralls:push']

task default: :test
