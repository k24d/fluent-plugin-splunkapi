require 'helper'

class SplunkAPIOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
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
    d = create_driver
    assert_equal 'rest', d.instance.protocol
    assert_equal '{TAG}', d.instance.source
    assert_equal 'fluent', d.instance.sourcetype
  end

  def test_write
    d = create_driver

    time = Time.parse("2010-01-02 13:14:15 UTC").to_i
    d.emit({"a"=>1}, time)
    d.emit({"a"=>2}, time)

    d.run
  end
end
