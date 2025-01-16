# frozen_string_literal: true

require 'ruby_changelog/version'
require 'ruby_changelog/configuration'
require 'ruby_changelog/entry'

module RubyChangelog
  HEADER = /### (.*)/.freeze
  CONTRIBUTOR = '[@%<user>s]: https://github.com/%<user>s'
  EOF = "\n"

  class Error < StandardError; end
  class ConfigurationError < StandardError; end

  require 'ruby_changelog/railtie' if defined?(Rails)

  class << self
    def configuration
      @configuration ||= RubyChangelog::Configuration.new
    end

    def configure
      yield(configuration)
    end

    def pending?
      entry_paths.any?
    end

    def entry_paths
      dir_name = RubyChangelog.configuration.entries_path.dup
      FileUtils.mkdir_p(dir_name)

      Dir["#{dir_name}*"]
    end

    def read_entries
      entry_paths.to_h { |path| [path, File.read(path)] }
    end
  end

  def initialize(content: File.read(PATH), entries: Changelog.read_entries)
    require 'strscan'

    parse(content)
    @entries = entries
  end

  def and_delete!
    @entries.each_key { |path| File.delete(path) }
  end

  def merge!
    File.write(RubyChangelog.configuration.changelog_filename, merge_content)
    self
  end

  def unreleased_content
    entry_map = parse_entries(@entries)
    merged_map = merge_entries(entry_map)
    merged_map.flat_map { |header, things| ["### #{header}\n", *things, ''] }.join("\n")
  end

  def merge_content
    merged_content = [@header, unreleased_content, @rest.chomp, *new_contributor_lines].join("\n")

    merged_content << EOF
  end

  def new_contributor_lines
    unique_contributor_names = contributors.map { |user| format(CONTRIBUTOR, user: user) }.uniq

    unique_contributor_names.reject { |line| @rest.include?(line) }
  end

  def contributors
    contributors = @entries.values.flat_map do |entry|
      entry.match(/\. \((?<contributors>.+)\)\n/)[:contributors].split(',')
    end

    contributors.join.scan(RubyChangelog.configuration.user_signature).flatten
  end

  private

  def merge_entries(entry_map)
    all = @unreleased.merge(entry_map) { |_k, v1, v2| v1.concat(v2) }
    canonical = RubyChangelog.configuration.type_mapping.values.to_h { |v| [v, nil] }
    canonical.merge(all).compact
  end

  def parse(content)
    ss = StringScanner.new(content)

    @header = ss.scan_until(RubyChangelog.configuration.unreleased_header)
    @unreleased = parse_release(ss.scan_until(/\n(?=## )/m))
    @rest = ss.rest
  end

  # @return [Hash<type, Array<String>]]
  def parse_release(unreleased)
    unreleased
      .lines
      .map(&:chomp)
      .reject(&:empty?)
      .slice_before(HEADER)
      .to_h do |header, *entries|
        [HEADER.match(header)[1], entries]
      end
  end

  def parse_entries(path_content_map)
    changes = Hash.new { |h, k| h[k] = [] }

    path_content_map.each do |path, content|
      header = RubyChangelog.configuration.type_mapping.fetch(entry_type(path))

      changes[header].concat(content.lines.map(&:chomp))
    end

    changes
  end

  def entry_type(path)
    RubyChangelog.configuration.entry_path_match_regexp.match(path)[:type].to_sym
  end
end
