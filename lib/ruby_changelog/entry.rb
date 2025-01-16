# frozen_string_literal: true

module RubyChangelog
  Entry = Struct.new(:type, :body, :ref_type, :ref_id, :user, keyword_init: true) do
    def initialize(type:, body: last_commit_title, ref_type: nil, ref_id: nil, user: github_user)
      id, body = extract_id(body)
      ref_id ||= id || 'x'
      ref_type ||= id ? :issues : :pull
      super
    end

    def write
      File.write(path, content)
      path
    end

    def path
      format(
        RubyChangelog.configuration.entry_path_template,
        type: type, name: str_to_filename(body), timestamp: Time.now.strftime('%Y%m%d%H%M%S')
      )
    end

    def content
      title = body.dup
      title += '.' unless title.end_with? '.'

      "* #{ref}: #{title} ([@#{user}][])\n"
    end

    def ref
      "[##{ref_id}](#{RubyChangelog.configuration.repo_url}/#{ref_type}/#{ref_id})"
    end

    def last_commit_title
      `git log -1 --pretty=%B`.lines.first.chomp
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
          return result if s.length > MAX_LENGTH

          s
        end
    end

    def github_user
      user = `git config --global credential.username`.chomp
      warn 'Set your username with `git config --global credential.username "myusernamehere"`' if user.empty?

      user
    end

    private

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
