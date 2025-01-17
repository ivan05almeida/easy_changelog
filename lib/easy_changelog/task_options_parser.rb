# frozen_string_literal: true

require 'optparse'

class EasyChangelog
  class TaskOptionsParser
    def self.parse(type, args)
      options = {}
      opts = OptionParser.new
      args = opts.order!(args) {}

      opts.banner = "Usage: rake changelog:#{type} [options]"

      opts.on('-r', '--ref-id=ARG', 'Ref ID') { |arg| options[:ref_id] = arg }
      opts.on('-R', '--ref-type=ARG', 'Ref type (issues|pull|commit)') { |arg| options[:ref_type] = arg }
      opts.on('-t', '--task-id=ARG', 'Task ID') { |arg| options[:task_id] = arg }
      opts.on('-T', '--task-url=ARG', 'Tasks URL') { |arg| options[:tasks_url] = arg }

      opts.on('-h', '--help', 'Prints this helper') do
        puts opts
        exit
      end

      opts.parse!(args)

      options
    end
  end
end
