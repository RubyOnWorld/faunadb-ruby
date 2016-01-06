require File.expand_path('../test_helper', __FILE__)

class ClientTest < FaunaTest
  def test_decode_ref
    test_ref = Ref.new('classes', RandomHelper.random_string, RandomHelper.random_number)

    test_client = stub_client :get, 'tests/ref', [200, {}, { resource: test_ref.to_hash }.to_json]
    response = test_client.get('tests/ref')
    assert response.is_a?(Ref)
    assert_equal test_ref, response
  end

  def test_decode_set
    test_set_match = RandomHelper.random_string
    test_set_index = Ref.new("indexes/#{RandomHelper.random_string}")

    set = Set.new(match: test_set_match, index: test_set_index)
    test_client = stub_client :get, 'tests/set', [200, {}, { resource: set }.to_json]

    response = test_client.get('tests/set')
    assert response.is_a?(Set)
    assert_equal test_set_match, response.value[:match]
    assert_equal test_set_index.value, response.value[:index].value
  end

  def test_decode_obj
    test_obj_key = RandomHelper.random_string.to_sym
    test_obj_value = RandomHelper.random_string

    test_client = stub_client(:get, 'tests/obj',
      [200, {}, { resource: { :@obj => { test_obj_key => test_obj_value } } }.to_json])

    response = test_client.get('tests/obj')
    assert response.is_a?(Hash)
    assert_equal test_obj_value, response[test_obj_key]
  end

  def test_decode_ts
    test_ts = Time.at(0).utc
    test_client = stub_client(:get, 'tests/ts',
      [200, {}, { resource: { :@ts => '1970-01-01T00:00:00+00:00' } }.to_json])
    response = test_client.get('tests/ts')
    assert response.is_a? Time
    assert_equal test_ts, response
  end

  def test_decode_date
    test_date = Date.new(1970, 1, 1)
    test_client = stub_client(:get, 'tests/date',
      [200, {}, { resource: { :@date => '1970-01-01' } }.to_json])
    response = test_client.get('tests/date')
    assert response.is_a? Date
    assert_equal test_date, response
  end

  def test_invalid_key
    client = get_client(secret: 'xyz')
    assert_raises Unauthorized do
      client.get(db_ref)
    end
  end

  def test_ping
    assert_equal 'Scope Global is OK', client.ping
    assert_equal 'Scope Global is OK', client.ping(scope: 'global')
    assert_equal 'Scope Local is OK', client.ping(scope: 'local')
    assert_equal 'Scope Node is OK', client.ping(scope: 'node')
    assert_equal 'Scope All is OK', client.ping(scope: 'all')
  end

  def test_get
    assert client.get('classes')[:data].is_a?(Array)
  end

  def test_post
    cls = create_class
    assert client.get(cls[:ref]) == cls
  end

  def test_put
    create_class
    instance = create_instance
    instance = client.put instance[:ref], data: { a: 2 }

    assert_equal 2, instance[:data][:a]

    instance = client.put instance[:ref], data: { b: 3 }
    assert !instance[:data].include?(:a)
    assert_equal 3, instance[:data][:b]
  end

  def test_patch
    create_class
    instance = create_instance
    instance = client.patch instance[:ref], data: { a: 1 }
    instance = client.patch instance[:ref], data: { b: 2 }
    assert_equal({ a: 1, b: 2 }, instance[:data])
  end

  def test_delete
    cls_ref = create_class[:ref]
    client.delete cls_ref
    assert_raises(NotFound) do
      client.get cls_ref
    end
  end

  def test_logging
    logged = nil
    client = self.get_client observer: (ClientLogger.logger do |_|
      logged = _
    end)
    client.ping

    lines = logged.split "\n"

    read_line = lambda do
      lines.shift
    end

    assert_equal 'Fauna GET /ping', read_line.call
    assert_match /^  Credentials:/, read_line.call
    assert_equal '  Response headers: {', read_line.call
    # Skip through headers
    loop do
      line = read_line.call
      unless line.start_with? '    '
        assert_equal '  }', line
        break
      end
    end
    assert_equal '  Response JSON: {', read_line.call
    assert_equal '    "resource": "Scope Global is OK"', read_line.call
    assert_equal '  }', read_line.call
    assert_match /^  Response \(200\): API processing \d+ms, network latency \d+ms$/, read_line.call
  end

private

  def stub_client(method, url, response, params = {})
    stubs = Faraday::Adapter::Test::Stubs.new
    stubs.send(method, url) do
      response
    end
    Client.new({ adapter: [:test, stubs] }.merge params)
  end

  def create_class
    client.post 'classes', name: 'my_class'
  end

  def create_instance
    client.post 'classes/my_class', {}
  end
end
