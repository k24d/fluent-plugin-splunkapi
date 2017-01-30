require 'helper'

class SplunkAPIOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
    @time = Time.parse("2010-01-02 13:14:15 UTC").to_i
  end

  CONFIG = %[
    protocol rest
    server localhost:8089
    verify false
    auth admin:changeme
  ]

  def create_driver(conf=CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::SplunkAPIOutput, tag).configure(conf)
  end

  def test_configure
    # default
    d = create_driver CONFIG
    assert_equal 'rest', d.instance.protocol
    assert_equal '{TAG}', d.instance.source
    assert_equal 'fluent', d.instance.sourcetype
  end

  def test_write_json
    d = create_driver [CONFIG, "format json", "time_format unixtime"].join "\n"

    d.emit({"a"=>1}, @time)
    d.emit({"a"=>2}, @time)

    result = d.run
    assert_equal 2, result['test'].size
    assert_equal "#{@time}: {\"a\":1}", result['test'][0].strip
  end

  def test_write_json_with_timestamp
    d = create_driver [CONFIG, "format json", "timestamp_field true", "time_format unixtime"].join "\n"

    d.emit({"a"=>1}, @time)
    d.emit({"a"=>2}, @time)

    result = d.run
    assert_equal 2, result['test'].size
    assert_equal({"a" => 1, "timestamp" => @time.to_s}, JSON.parse(result['test'][0]))
  end

  def test_write_kvp
    d = create_driver [CONFIG, "format kvp", "time_format unixtime"].join "\n"

    d.emit({"a"=>1}, @time)
    d.emit({"a"=>2}, @time)

    result = d.run
    assert_equal 2, result['test'].size
    assert_equal "#{@time}: a=\"1\"", result['test'][0].strip
  end

  def test_write_kvp_without_time
    d = create_driver [CONFIG, "format kvp", "time_format none"].join "\n"

    d.emit({"a"=>1}, @time)
    d.emit({"a"=>2}, @time)

    result = d.run
    assert_equal 2, result['test'].size
    assert_equal "a=\"1\"", result['test'][0].strip
  end
end
