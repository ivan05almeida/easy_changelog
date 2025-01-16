# frozen_string_literal: true

require 'ruby_changelog'
require 'rails'

module RubyChangelog
  class Railtie < Rails::Railtie
    railtie_name :ruby_changelog

    rake_tasks do
      load 'tasks/changelog.rake'
    end
  end
end
