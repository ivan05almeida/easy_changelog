# EasyChangelog

<strong>EasyChangelog</strong> is a tool easily manage your project changelog. This project is based on Rubocop changelog style with more customizations to your needs.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add easy_changelog

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install easy_changelog

## Usage

### Configuration

Write an easy_changelog.rb at the initiliazers folder in order to config the gem accordingly to your project

```ruby
EasyChangelog.configure do |config|
    config.entries_path = 'changelog/'                      # the folder where the changelog entries will be stored
    config.changelog_filename = 'CHANGELOG.md'              # the filename of your changelog
    config.main_branch = 'master'                           # main branch for repository
    config.filename_max_length = 50                         # max filename length
    config.include_empty_task_id = false                    # includes a [] when task id and the project still need to track tasks without tickets

    config.unreleased_header = '## master (unreleased)'     # Header of changelog where the unreleased entries are located
    config.user_signature = /\[@([\w-]+)\]\[\]/             # Regexp to list unique contributors of the project

    config.type_mapping = {                                 # Entry types and their Section Names to be displayed at Changelog
        new: 'New features',
        fix: 'Bug fixes'
    }

    config.repo_url = <GITHUB_REPO_URL>                     # URL to your repository (Can also be defined with REPOSITORY_URL var var)
    config.tasks_url = <YOUR_ISSUE_TRACKING_URL>            # URL to your organization issue tracker (ex: JIRA, Asana, Wrike. Can also be defined with REPOSITORY_URL env var)
end
```

### Entries Types

By default this gem supports new and fix changelog entries. Check the Configuration section to see how you can change this with type_mapping option.

For each supported type, you can call their rake task:

```
$ bundle exec rake changelog:new -- --ref-id=1234 --ref-type=pull
```

To know all options available you can add `--help` option to the command

By default if a ref id is given the ref-type default will be pull, if it's blank it will be commit and the changelog will then contain reference with the short git commit ID instead.

You can still pass a ref-id and set ref-type to issues to add a reference to a issue card

### Prepare changelog to deployment/release

To add the entries to your changelog just need to run

```
$ bundle exec rake changelog:merge
```

If you want to check if there are entries to merge:
```
$ bundle exec rake changelog:check_clean
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/easy_changelog. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/easy_changelog/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Ruby::Changelog project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/easy_changelog/blob/main/CODE_OF_CONDUCT.md).
