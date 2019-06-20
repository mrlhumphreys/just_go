# JustGo

A go egnine written in ruby. It provides a representation of go game complete with rules enforcement and serialisation.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'just_go'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install just_go

## Usage

To start, a new game can be instantiated with the default state:

```ruby
  game_state = JustCheckers::GameState.default
```

Moves can be made by passing in the player number and the id of the point. It will return true if the move is valid, otherwise it will return false.

```ruby
  game_state.move(1, 63);
```

The last change with all its details are found in the `last_change` attribute.

```ruby
  game_state.last_change
```

If something happens, errors may be found in the errors attribute

```ruby
  game_state.errors
```

THe winner can be found by calling winner on the object

```ruby
  game_state.winner
```

Also, the game can be serialized into a hash.

```ruby
  game_state.as_json
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mrlhumphreys/just_go. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the JustGo project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/mrlhumphreys/just_go/blob/master/CODE_OF_CONDUCT.md).
