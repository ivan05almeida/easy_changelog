# frozen_string_literal: true

class EasyChangelog
  Entry = Struct.new(:type, :body, :ref_type, :ref_id, :card_id, :cards_url, :branch_name, :user, keyword_init: true) do
    def initialize(type:, body: last_commit_title, ref_type: nil, ref_id: nil, card_id: nil, cards_url: nil,
                   user: github_user, branch_name: nil)
      id, body = EasyChangelog::Utility.extract_id(body)
      ref_id ||= id || last_commit_id
      ref_type ||= id ? :pull : :commit
      card_id ||= EasyChangelog::Utility.discover_card_id(branch_name)

      super
    end

    def write
      EasyChangelog::Utility.ensure_entries_dir_exists

      File.write(path, content)
      path
    end

    def path
      filename = EasyChangelog::Utility.str_to_filename(body)
      options = { type: type, name: filename, timestamp: Time.now.strftime('%Y%m%d%H%M%S') }

      format(EasyChangelog.configuration.entry_path_template, options)
    end

    def content
      title = body.dup
      title += '.' unless title.end_with? '.'

      options = { ref: ref, card_ref: card_ref, title: title, username: user }

      format(EasyChangelog.configuration.entry_row_template, options)
    end

    def ref
      raise ArgumentError, 'ref_type must be issues, pull, or commit' unless %w[issues pull commit].include?(ref_type)

      "[##{ref_id}](#{EasyChangelog.configuration.repo_url}/#{ref_type}/#{ref_id})"
    end

    def card_ref
      return EasyChangelog.configuration.include_empty_card_id ? '[] ' : '' if card_id.nil? || card_id.empty?

      link = "[#{card_id}]"
      base_url = cards_url || EasyChangelog.configuration.cards_url
      link += "(#{base_url}/#{card_id})" if base_url

      link
    end

    def last_commit_title
      `git log -1 --pretty=%B`.lines.first.chomp
    end

    def last_commit_id
      `git log -n1 --format="%h"`.chomp
    end

    def github_user
      user = `git config --global credential.username`.chomp
      warn 'Set your username with `git config --global credential.username "myusernamehere"`' if user.empty?

      user
    end
  end
end
