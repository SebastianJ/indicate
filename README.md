# Indicate

Technical Analysis signals & indicators for trading stocks, bonds, currencies, cryptos etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'indicate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install indicate

## Usage

Since talib_ruby hasn't been updated in a while on RubyGems, this gem uses a forked version hosted on Github.

Because of this, you'll need to add the following to your app's Gemfile:

```ruby
gem 'talib_ruby', github: 'edbond/talib-ruby'
gem 'ta-indicator', '~> 0.1.1'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/indicate. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Indicate project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/indicate/blob/master/CODE_OF_CONDUCT.md).
