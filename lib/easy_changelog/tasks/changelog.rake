# frozen_string_literal: true

require 'easy_changelog'
require 'easy_changelog/task_options_parser'

namespace :changelog do
  def load_config
    EasyChangelog.configuration.load_config
  end

  EasyChangelog.configuration.changelog_types.each do |type|
    desc "Create a Changelog entry (#{type})"
    task type do
      load_config
      options = EasyChangelog::TaskOptionsParser.parse(type, ARGV)
      options[:type] = type

      entry = EasyChangelog::Entry.new(**options)
      path = entry.write
      cmd = "git add #{path}"
      sh cmd
      puts "Entry '#{path}' created and added to git index"
    end
  end

  desc 'Create a Changelog entry (default)'
  task :new do
    load_config
    options = EasyChangelog::TaskOptionsParser.parse(:new, ARGV)
    options[:type] = :new

    entry = EasyChangelog::Entry.new(**options)
    path = entry.write
    cmd = "git add #{path}"
    sh cmd
    puts "Entry '#{path}' created and added to git index"
  end

  desc 'Merge entries and delete them'
  task :merge do
    load_config
    raise 'No entries!' unless EasyChangelog.pending?

    EasyChangelog.merge_and_delete!
    cmd = "git commit -a -m 'Update Changelog'"
    puts cmd
    sh cmd
  end

  desc 'Check for no pending changelog entries'
  task :check_clean do
    load_config
    next unless EasyChangelog.pending?

    puts '*** Pending changelog entries!'
    puts 'Do `bundle exec rake changelog:merge`'
    exit(1)
  end

  desc 'Add release entry'
  task :release do
    load_config
    EasyChangelog.release!
    cmd = "git commit -a -m 'Update Changelog'"
    puts cmd
    sh cmd
  end
end
