# frozen_string_literal: true

require 'dotenv/load'
require 'date'

class EasyChangelog
  class Configuration
    attr_accessor :changelog_filename, :main_branch, :filename_max_length, :include_empty_card_id, :cards_url,
                  :entry_row_format
    attr_reader :entries_path, :unreleased_header, :entry_path_format, :user_signature, :type_mapping, :card_id_regex,
                :entries_order, :card_id_normalizer

    attr_writer :repo_url, :release_message_template

    CONFIG_PATHS = %w[
      ./.easy_changelog.rb
      ./config/initializers/easy_changelog.rb
      ./config/easy_changelog.rb
    ].freeze

    # rubocop:disable Metrics/AbcSize
    def initialize
      @entries_path = 'changelog/'
      @entries_order = :asc
      @changelog_filename = 'CHANGELOG.md'

      @main_branch = 'master'
      @entry_path_format = '<type>_<name>_<timestamp>.md'
      @entry_row_format = '* <ref>: <card_ref> <title> (<username>)'
      @unreleased_header = /## #{Regexp.escape("#{@main_branch} (unreleased)")}/m
      @user_signature = Regexp.new(format(Regexp.escape('[@%<user>s][]'), user: '([\w-]+)'))

      @filename_max_length = 50
      @type_mapping = {
        breaking: { title: 'Breaking Changes', level: :major },
        feature: { title: 'New features', level: :minor },
        fix: { title: 'Bug fixes', level: :patch }
      }
      @include_empty_card_id = false

      @repo_url = ENV.fetch('REPOSITORY_URL', nil)
      @cards_url = ENV.fetch('CARDS_URL', nil)
      @card_id_regex = %r{(?<card_id>[^/]+)/(?:.+)}
      @release_message_template = -> { "## #{EasyChangelog::VERSION} (#{Date.today.iso8601})" }
    end
    # rubocop:enable Metrics/AbcSize

    def repo_url
      raise ConfigurationError, 'repo_url must be set' unless @repo_url

      @repo_url
    end

    def release_message_template
      raise ConfigurationError, 'release_message_template must be set' unless @release_message_template

      return @release_message_template unless @release_message_template.respond_to?(:call)

      message = @release_message_template.call
      message = "## #{message}" unless message.start_with?('## ')
      message
    end

    def card_regex=(value)
      raise ArgumentError, 'card_regex must be a Regexp' unless value.is_a?(Regexp)

      @card_regex = value
    end

    def card_id_normalizer=(value)
      raise ArgumentError, 'card_id_normalizer must be callable' unless value.respond_to?(:call)

      @card_id_normalizer = value
    end

    def unreleased_header=(value)
      @unreleased_header = /## #{Regexp.escape(value)}/m
    end

    def entries_path=(value)
      value += '/' unless value.end_with?('/')

      @entries_path = value
    end

    def entries_order=(value)
      value = value.to_sym
      raise ArgumentError, 'entries_order must be :asc or :desc' unless %i[asc desc].include?(value)

      @entries_order = value
    end

    def type_mapping=(value)
      raise ArgumentError, 'type_mapping must be a Hash or :loose' unless value.is_a?(Hash) || value == :loose

      @type_mapping = value
    end

    def loose?
      @type_mapping == :loose
    end

    def user_signature=(value)
      raise ArgumentError, 'user_signature must be a Regexp' unless value.is_a?(Regexp) || value.nil?

      @user_signature = value
    end

    def changelog_types
      return [] if @type_mapping == :loose

      @type_mapping.keys
    end

    def sections
      return [''] if @type_mapping == :loose

      @type_mapping.values.map { |v| v[:title] }
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

    def entry_row_match_regexp
      with_optional_card_ref = Regexp.escape(@entry_row_format).gsub('<card_ref>\\ ') { |match| "(?:#{match})?" }
      formula = with_optional_card_ref.gsub(/<(\w+)>/) { |match| "(?#{match}.+)" }

      Regexp.new(formula)
    end

    def entry_row_template
      @entry_row_format.gsub(/<(\w+)>/) { |_match| "%<#{Regexp.last_match(1)}>s" }
    end

    def load_config
      paths = CONFIG_PATHS.map { |file_path| File.expand_path(file_path) }
      path = paths.select { |file_path| File.exist?(file_path) }.first

      return unless path

      load(path)
    end
  end
end
