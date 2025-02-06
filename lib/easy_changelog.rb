# frozen_string_literal: true

require 'easy_changelog/version'
require 'easy_changelog/configuration'
require 'easy_changelog/utility'
require 'easy_changelog/entry'

class EasyChangelog
  HEADER = /### (.*)/.freeze
  CONTRIBUTOR = '[@%<user>s]: https://github.com/%<user>s'
  EOF = "\n"

  class Error < StandardError; end
  class ConfigurationError < StandardError; end
  class EmptyReleaseError < StandardError; end

  require 'easy_changelog/railtie' if defined?(Rails)

  class << self
    def configuration
      @configuration ||= EasyChangelog::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def pending?
      entry_paths.any?
    end

    def merge_and_delete!
      new.merge_and_delete!
    end

    def release!
      new.release!
    end

    def entry_paths
      Dir["#{EasyChangelog.configuration.entries_path}*"]
    end

    def read_entries
      entry_paths.to_h { |path| [path, File.read(path)] }
    end

    def release_count(pattern)
      File.read(EasyChangelog.configuration.changelog_filename).scan(pattern).size
    end
  end

  attr_reader :header, :entries

  def initialize(content: File.read(EasyChangelog.configuration.changelog_filename),
                 entries: EasyChangelog.read_entries)
    require 'strscan'

    @header, @unreleased, @rest = EasyChangelog::Utility.parse_changelog(content)
    @entries = entries
  end

  def merge_and_delete!
    merge!
    delete!
  end

  def merge!
    EasyChangelog::Utility.update_changelog(merge_content)
    self
  end

  def delete!
    @entries.each_key { |path| File.delete(path) }
  end

  def release!
    EasyChangelog::Utility.update_changelog(release_content)
    self
  end

  def unreleased_content
    entry_map = parse_entries(@entries)
    merged_map = merge_entries(entry_map)
    merged_map.flat_map do |header, things|
      if header.empty?
        [*things, '']
      else
        ["### #{header}\n", *things, '']
      end
    end.join("\n")
  end

  def merge_content
    merged_content = [@header, unreleased_content, @rest.chomp, *new_contributor_lines].join("\n")

    merged_content << EOF
  end

  def release_content
    unreleased = unreleased_content
    raise EmptyReleaseError, 'No unreleased content to release' if unreleased.empty?

    release_message = EasyChangelog.configuration.release_message_template
    release_message = "\n#{release_message}" unless release_message.start_with?("\n")

    released_content = [@header, release_message, unreleased, @rest.chomp, *new_contributor_lines].join("\n")
    released_content << EOF
  end

  def new_contributor_lines
    return [] unless EasyChangelog.configuration.user_signature

    unique_contributor_names = contributors.map { |user| format(CONTRIBUTOR, user: user) }.uniq

    unique_contributor_names.reject { |line| @rest.include?(line) }
  end

  def contributors
    @entries.values.flat_map do |entry|
      EasyChangelog::Utility.attr_from_entry(:username, entry)&.gsub(/@/, '')
    end
  end

  private

  def merge_entries(entry_map)
    all = @unreleased.merge(entry_map) do |_k, v1, v2|
      EasyChangelog.configuration.entries_order == :desc ? v2.concat(v1) : v1.concat(v2)
    end
    canonical = EasyChangelog.configuration.sections.to_h { |v| [v, nil] }
    canonical.merge(all).compact
  end

  def parse_entries(path_content_map)
    changes = Hash.new { |h, k| h[k] = [] }

    sorted_entries(path_content_map).each do |path, content|
      header = EasyChangelog::Utility.section_for(path)

      changes[header].concat(content.lines.map(&:chomp))
    end

    changes
  end

  def sorted_entries(path_content_map)
    sorted = path_content_map.sort_by { |path, _content| EasyChangelog::Utility.attr_from_path(:timestamp, path) }
    sorted = sorted.reverse if EasyChangelog.configuration.entries_order == :desc

    sorted
  end
end
