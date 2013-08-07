libdir = File.dirname(File.dirname(__FILE__)) + '/lib'
$LOAD_PATH.unshift libdir unless $LOAD_PATH.include?(libdir)

require "rubygems"
require "test/unit"
require "fauna"
require "securerandom"
require "mocha/setup"

FAUNA_ROOTKEY = ENV["FAUNA_ROOTKEY"]
FAUNA_DOMAIN = ENV["FAUNA_DOMAIN"]
FAUNA_SCHEME = ENV["FAUNA_SCHEME"]
FAUNA_PORT = ENV["FAUNA_PORT"]

if !(FAUNA_ROOTKEY && FAUNA_DOMAIN && FAUNA_SCHEME && FAUNA_PORT)
  raise "FAUNA_ROOTKEY, FAUNA_DOMAIN, FAUNA_SCHEME and FAUNA_PORT must be defined in your environment to run tests."
end

ROOT_CONNECTION = Fauna::Connection.new(:secret => FAUNA_ROOTKEY, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)

Fauna::Client.context(ROOT_CONNECTION) do
  Fauna::Database.new(:name => "fauna-ruby-test").delete rescue nil
  Fauna::Database.create(:name => "fauna-ruby-test")

  server_key = Fauna::Key.create :database => "fauna-ruby-test", :role => "server"
  client_key = Fauna::Key.create :database => "fauna-ruby-test", :role => "client"

  SERVER_CONNECTION = Fauna::Connection.new(:secret => server_key.secret, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)
  CLIENT_CONNECTION = Fauna::Connection.new(:secret => client_key.secret, :domain => FAUNA_DOMAIN, :scheme => FAUNA_SCHEME, :port => FAUNA_PORT)
end

# fixtures

Fauna::Client.context(SERVER_CONNECTION) do
  Fauna::Class.create :name => 'pigs'
  Fauna::Class.create :name => 'pigkeepers'
  Fauna::Class.create :name => 'visions'
  Fauna::Class.create :name => 'message_boards'
  Fauna::Class.create :name => 'posts'
  Fauna::Class.create :name => 'comments'
end

# test harness

class MiniTest::Unit::TestCase
  def setup
    @root_connection = ROOT_CONNECTION
    @server_connection = SERVER_CONNECTION
    @client_connection = CLIENT_CONNECTION
    Fauna::Client.push_context(@server_connection)
  end

  def teardown
    Fauna::Client.pop_context
  end

  def email
    "#{SecureRandom.random_number}@example.com"
  end

  def fail
    assert false, "Not implemented"
  end

  def pass
    assert true
  end

  def password
    SecureRandom.random_number.to_s
  end
end
