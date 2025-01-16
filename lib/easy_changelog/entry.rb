# frozen_string_literal: true

class EasyChangelog
  Entry = Struct.new(:type, :body, :ref_type, :ref_id, :task_id, :tasks_url, :user, keyword_init: true) do
    def initialize(type:, body: last_commit_title, ref_type: nil, ref_id: nil, task_id: nil, tasks_url: nil,
                   user: github_user)
      id, body = extract_id(body)
      ref_id ||= id || last_commit_id
      ref_type ||= id ? :pull : :commit
      super
    end

    def write
      dir_name = EasyChangelog.configuration.entries_path
      FileUtils.mkdir_p(dir_name) unless File.directory?(dir_name)

      File.write(path, content)
      path
    end

    def path
      format(
        EasyChangelog.configuration.entry_path_template,
        type: type, name: str_to_filename(body), timestamp: Time.now.strftime('%Y%m%d%H%M%S')
      )
    end

    def content
      title = body.dup
      title += '.' unless title.end_with? '.'

      "* #{ref}: #{task_ref} #{title} ([@#{user}][])\n"
    end

    def ref
      raise ArgumentError, 'ref_type must be issues, pull, or commit' unless %w[issues pull commit].include?(ref_type)

      "[##{ref_id}](#{EasyChangelog.configuration.repo_url}/#{ref_type}/#{ref_id})"
    end

    def task_ref
      return EasyChangelog.configuration.include_empty_task_id ? '[] ' : '' if task_id.nil? || task_id.empty?

      link = "[#{task_id}]"
      base_url = tasks_url || EasyChangelog.configuration.tasks_url
      link += "(#{base_url}/#{task_id})" if base_url

      link
    end

    def last_commit_title
      `git log -1 --pretty=%B`.lines.first.chomp
    end

    def last_commit_id
      `git log -n1 --format="%h"`.chomp
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
