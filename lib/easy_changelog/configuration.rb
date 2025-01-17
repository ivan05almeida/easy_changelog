# frozen_string_literal: true

require 'dotenv/load'

class EasyChangelog
  class Configuration
    attr_accessor :changelog_filename, :main_branch, :filename_max_length, :include_empty_task_id, :tasks_url
    attr_reader :entries_path, :unreleased_header, :entry_path_format, :user_signature, :type_mapping
    attr_writer :repo_url, :tasks_url

    def initialize
      @entries_path = 'changelog/'
      @changelog_filename = 'CHANGELOG.md'

      @main_branch = 'master'
      @entry_path_format = '<type>_<name>_<timestamp>.md'
      @unreleased_header = /#{Regexp.escape("## #{@main_branch} (unreleased)")}/m
      @user_signature = Regexp.new(format(Regexp.escape('[@%<user>s][]'), user: '([\w-]+)'))

      @filename_max_length = 50
      @type_mapping = { new: 'New features', fix: 'Bug fixes' }
      @include_empty_task_id = false

      @repo_url = ENV.fetch('REPOSITORY_URL', nil)
      @tasks_url = ENV.fetch('TASKS_URL', nil)
    end

    def repo_url
      raise ConfigurationError, 'repo_url must be set' unless @repo_url

      @repo_url
    end

    def unreleased_header=(value)
      @unreleased_header = /#{Regexp.escape(value)}/m
    end

    def entries_path=(value)
      value += '/' unless value.end_with?('/')

      @entries_path = value
    end

    def type_mapping=(value)
      raise ArgumentError, 'type_mapping must be a Hash' unless value.is_a?(Hash)

      @type_mapping = value
    end

    def user_signature=(value)
      raise ArgumentError, 'user_signature must be a Regexp' unless value.is_a?(Regexp)

      @user_signature = value
    end

    def changelog_types
      @type_mapping.keys
    end

    def entry_path_match_regexp
      formula = @entry_path_format.gsub(/<(\w+)>/) do |match|
        matcher = match == '<type>' ? '[^_]' : '.'
        "(?#{match}#{matcher}+)"
      end

      Regexp.new("(?:#{entries_path})?#{formula}")
    end

    def entry_path_template
      File.join(entries_path, @entry_path_format.gsub(/<(\w+)>/) { |_match| "%<#{Regexp.last_match(1)}>s" })
    end
  end
end
