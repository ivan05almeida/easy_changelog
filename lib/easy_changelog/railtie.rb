# frozen_string_literal: true

require 'easy_changelog'
require 'rails'

class EasyChangelog
  class Railtie < Rails::Railtie
    railtie_name :easy_changelog

    rake_tasks do
      load 'tasks/changelog.rake'
    end
  end
end
