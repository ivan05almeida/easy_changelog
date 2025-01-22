# frozen_string_literal: true

require 'easy_changelog'
require 'rails'

class EasyChangelog
  class Railtie < Rails::Railtie
    railtie_name :easy_changelog

    rake_tasks do
      path = File.expand_path(__dir__)
      Dir.glob("#{path}/tasks/**/*.rake").each { |f| load f }
    end
  end
end
