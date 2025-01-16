# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/test_*.rb']
end

require 'rubocop/rake_task'

RuboCop::RakeTask.new

path = File.expand_path(__dir__)
Dir.glob("#{path}/lib/ruby_changelog/tasks/**/*.rake").each { |f| import f }

task default: %i[test rubocop]
