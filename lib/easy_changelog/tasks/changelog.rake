# frozen_string_literal: true

require 'easy_changelog'
require 'easy_changelog/task_options_parser'

namespace :changelog do
  EasyChangelog.configuration.changelog_types.each do |type|
    desc "Create a Changelog entry (#{type})"
    task type do
      options = EasyChangelog::TaskOptionsParser.parse(type, ARGV)
      options[:type] = type

      entry = EasyChangelog::Entry.new(**options)
      path = entry.write
      cmd = "git add #{path}"
      sh cmd
      puts "Entry '#{path}' created and added to git index"
    end
  end

  desc 'Merge entries and delete them'
  task :merge do
    raise 'No entries!' unless EasyChangelog.pending?

    EasyChangelog.merge_and_delete!
    cmd = "git commit -a -m 'Update Changelog'"
    puts cmd
    sh cmd
  end

  desc 'Check for no pending changelog entries'
  task :check_clean do
    next unless EasyChangelog.pending?

    puts '*** Pending changelog entries!'
    puts 'Do `bundle exec rake changelog:merge`'
    exit(1)
  end

  desc 'Add release entry'
  task :release do
    EasyChangelog.release!
    cmd = "git commit -a -m 'Update Changelog'"
    puts cmd
    sh cmd
  end
end
