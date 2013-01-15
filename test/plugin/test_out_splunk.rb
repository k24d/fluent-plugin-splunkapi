require 'helper'

class SplunkOutputTest < Test::Unit::TestCase
  def setup
    Fluent::Test.setup
  end

  CONFIG = %[
#    host test
#    access_token xxx
#    project_id xxx
  ]

  def create_driver(conf=CONFIG, tag='test')
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::SplunkOutput, tag).configure(conf)
  end

  def test_configure
    # default
    d = create_driver
    assert_equal 'storm', d.instance.protocol
    assert_equal 'fluent:{TAG}', d.instance.source
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
