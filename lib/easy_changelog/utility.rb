# frozen_string_literal: true

class EasyChangelog
  class Utility
    class << self
      def ensure_entries_dir_exists
        dir_name = EasyChangelog.configuration.entries_path
        FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)
      end

      # rubocop:disable Metrics/MethodLength
      def parse_changelog(content)
        ss = StringScanner.new(content)

        header = ss.scan_until(EasyChangelog.configuration.unreleased_header)
        unreleased = ss.scan_until(/\n(?=## )/m)

        if unreleased.nil?
          unreleased = parse_unreleased_entries(ss.rest)
          rest = ''
        else
          unreleased = parse_unreleased_entries(unreleased)
          rest = ss.rest
        end

        [header, unreleased, rest]
      end
      # rubocop:enable Metrics/MethodLength

      def update_changelog(content)
        File.write(EasyChangelog.configuration.changelog_filename, content)
      end

      def attr_from_path(var_name, path)
        EasyChangelog.configuration.entry_path_match_regexp.match(path)[var_name.to_sym]
      end

      def attr_from_entry(var_name, entry)
        EasyChangelog.configuration.entry_row_match_regexp.match(entry)[var_name.to_sym]
      end

      def section_for(path)
        entry_type = attr_from_path(:type, path).to_sym

        return '' if EasyChangelog.configuration.loose?

        EasyChangelog.configuration.type_mapping[entry_type][:title]
      end

      def discover_card_id(branch_name)
        return if EasyChangelog.configuration.card_id_regex.nil?

        branch_name ||= `git rev-parse --abbrev-ref HEAD`
        return if branch_name == EasyChangelog.configuration.main_branch

        id = EasyChangelog.configuration.card_id_regex.match(branch_name)&.named_captures&.fetch('card_id', nil)

        normalize_card_id(id)
      end

      def extract_id(body)
        /^\[Fix(?:es)? #(\d+)\] (.*)/.match(body)&.captures || [nil, body]
      end

      def str_to_filename(str)
        str
          .split
          .reject(&:empty?)
          .map { |s| prettify(s) }
          .inject do |result, word|
            s = "#{result}_#{word}"
            return result if s.length > EasyChangelog.configuration.filename_max_length

            s
          end
      end

      private

      def normalize_card_id(id)
        return id unless EasyChangelog.configuration.card_id_normalizer

        EasyChangelog.configuration.card_id_normalizer.call(id)
      end

      # @return [Hash<type, Array<String>]]
      def parse_unreleased_entries(unreleased)
        entries = unreleased.lines.map(&:chomp).reject(&:empty?)

        return { '' => entries } if EasyChangelog.configuration.loose?

        entries.slice_before(HEADER).to_h { |header, *header_entries| [HEADER.match(header)[1], header_entries] }
      end

      def prettify(str)
        str.gsub!(/\W/, '_')

        # Separate word boundaries by `_`.
        str.gsub!(/([A-Z]+)(?=[A-Z][a-z])|([a-z\d])(?=[A-Z])/) do
          (Regexp.last_match(1) || Regexp.last_match(2)) << '_'
        end

        str.gsub!(/\A_+|_+\z/, '')
        str.downcase!
        str
      end
    end
  end
end
