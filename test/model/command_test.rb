require File.expand_path('../../test_helper', __FILE__)

class CommandTest < ActiveModel::TestCase
  include ActiveModel::Lint::Tests

  class Command < Fauna::Command
  end

  def setup
    super
    @model = Command.new
  end

  # def test_class_name
  #   assert_equal 'users', User.ref
  # end

  def test_create
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_save
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_update
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_find
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end

  def test_destroy
    Fauna::Client.context(@publisher_connection) do
      fail
    end
  end
end
