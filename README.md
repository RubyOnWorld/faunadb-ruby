# FaunaDB

Ruby driver for [FaunaDB](https://faunadb.com).

## Installation

The FaunaDB ruby driver is distributed as a gem. Install it via:

    $ gem install fauna

Or if you use Bundler, add it to your application's `Gemfile`:

    gem 'fauna'

And then execute:

    $ bundle

## Documentation

The driver documentation is [hosted on GitHub Pages](https://faunadb.github.io/faunadb-ruby/).

Please see the [FaunaDB Documentation](https://fauna.com/documentation) for
a complete API reference, or look in
[`/test`](https://github.com/faunadb/faunadb-ruby/tree/master/test) for more
examples.

## Compatibility

Tested and compatible with the following ruby versions:

* MRI 1.9.3
* MRI 2.2.3
* Jruby 1.7.19

## Basic Usage

First, require the gem:

```ruby
require 'fauna'
```

### Creating a Client

All API requests pass through a `Fauna::Client`. Creating a client
requires either an admin key, server key, client key, or a token.

```ruby
server_key = 'ls8AkXLdakAAAALPAJFy3LvQAAGwDRAS_Prjy6O8VQBfQAlZzwAA'
```

Now we can make a database-level client:

```ruby
$fauna = Fauna::Client.new(secret: server_key)
```

You can optionally configure an `observer` on the client. To ease
debugging, we provide a simple logging observer at
`Fauna::ClientLogger.logger`, which you can configure as such:

```ruby
require 'logger'
logger = Logger.new(STDERR)
observer = Fauna::ClientLogger.logger { |log| logger.debug(log) }

$fauna = Fauna::Client.new(
  secret: server_key,
  observer: observer)
```

### Using the Client

Now that we have a client, we can start performing queries:

```ruby
# Create a class
$fauna.query { create ref('classes'), name: 'users' }

# Create an instance of the class
taran = $fauna.query do
  create ref('classes/users'), data: { email: 'taran@example.com' }
end

# Update the instance
taran = $fauna.query do
  update taran[:ref], data: {
    name: 'Taran',
    profession: 'Pigkeeper'
  }
end

# Page through a set
pigkeepers = Fauna::Query.expr { match(ref('indexes/users_by_profession'), 'Pigkeeper') }
oracles = Fauna::Query.expr { match(ref('indexes/users_by_profession'), 'Oracle') }

$fauna.query { paginate(union(pigkeepers, oracles)) }

# Delete the user
$fauna.query { delete user[:ref] }
```

## Running Tests

You can run tests against FaunaDB Cloud yourself.
[Create an admin key](https://fauna.com/account/keys) and set
`FAUNA_ROOT_KEY` environment variable to it's secret. Then run `rake test`:

```bash
export FAUNA_ROOT_KEY='kqnPAbijGhkgAAC03-36hjCvcTnWf4Pl8w97UE1HeWo'
rake test
```

To run a single test, use e.g. `ruby test/client_test.rb`.

Coverage is automatically run as part of the tests. After running tests, check
`coverage/index.html` for the coverage report. If using jruby, use
`JRUBY_OPTS="--debug" bundle exec rake test` to ensure coverage is generated
correctly.

## Contributing

GitHub pull requests are very welcome.

## LICENSE

Copyright 2016 [Fauna, Inc.](https://fauna.com/)

Licensed under the Mozilla Public License, Version 2.0 (the
"License"); you may not use this software except in compliance with
the License. You may obtain a copy of the License at

[http://mozilla.org/MPL/2.0/](http://mozilla.org/MPL/2.0/)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied. See the License for the specific language governing
permissions and limitations under the License.
