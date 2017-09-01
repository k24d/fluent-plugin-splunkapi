# NOTE: THIS PLUGIN IS OBSOLETE

Splunk recently introduced "HTTP Event Collector (HEC)", which is much better
than the traditional API used in this plugin:

http://dev.splunk.com/view/event-collector/SP-CAAAE6M

This plugin won't support HEC.  Please try other fluentd plugins or use HEC directly.

# Fluent::Plugin::SplunkAPI, a plugin for [Fluentd](http://fluentd.org)

Splunk output plugin for Fluent event collector.

This plugin makes use of the following APIs:

Splunk REST API:

  http://docs.splunk.com/Documentation/Splunk/latest/RESTAPI/RESTinput

Splunk Storm API:

  http://docs.splunk.com/Documentation/Storm/latest/User/UseStormsRESTAPI

## Notes

Although this plugin is capable of sending Fluent events directly to
Splunk servers or Splunk Storm, it is not recommended to do so.
Please use "Universal Forwarder" as a gateway, as described below.

It is known that this plugin has several issues of performance and
error handling in dealing with large data sets.  With a local/reliable
forwarder, you can aggregate a number of events locally and send them
to a server in bulk.

In short, I'd recommend to install a forwarder in each host, and use
this plugin to deliver events to the local forwarder:

    <match **>
      # Deliver events to the local forwarder.
      type splunkapi
      protocol rest
      server 127.0.0.1:8089
      verify false
      auth admin:changeme

      # Convert fluent tags to Splunk sources.
      # If you set an index, "check_index false" is required.
      host YOUR-HOSTNAME
      index SOME-INDEX
      check_index false
      source {TAG}
      sourcetype fluent

      # TIMESTAMP: key1="value1" key2="value2" ...
      time_format unixtime
      format kvp

      # Memory buffer with a short flush internal.
      buffer_type memory
      buffer_queue_limit 16
      buffer_chunk_limit 8m
      flush_interval 2s
    </match>

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-splunkapi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-splunkapi

## Configuration

Put the following lines to your fluent.conf:

    <match **>
      type splunkapi

      #
      # Splnk Server
      #

      # protocol: API protocol version
      # values: rest, storm
      # default: rest
      protocol rest

      # server: Splunk server host and port
      # default: localhost:8089
      server localhost:8089

      # verify: SSL server verification
      # default: true
      #verify false

      # auth: username and password
      auth admin:pass

      #
      # Splnk Storm
      #

      # protocol: API protocol version.
      # values: rest, storm
      # default: rest
      #protocol storm

      # access_token: for Splunk Storm
      #access_token YOUR-ACCESS-TOKEN

      # access_token: for Splunk Storm
      #project_id YOUR-PROJECT-ID

      #
      # Event Parameters
      #

      # host: 'host' parameter passed to Splunk
      host YOUR-HOSTNAME

      # index: 'index' parameter passed to Splunk (REST only)
      # default: <none>
      #index main

      # check_index: 'check-index' parameter passed to Splunk (REST only)
      # default: <none>
      #check_index false

      # host: 'source' parameter passed to Splunk
      # default: {TAG}
      #
      # "{TAG}" will be replaced by fluent tags at runtime
      source {TAG}

      # sourcetype: 'sourcetype' parameter passed to Splunk
      # default: fluent
      sourcetype fluent

      #
      # Formatting Parameters
      #

      # time_format: the time format of each event
      # value: none, unixtime, localtime, splunk (to let Splunk parse it from 'time' key) or any time format string
      # default: localtime
      time_format localtime

      # format: the text format of each event
      # value: json, kvp, or text
      # default: json
      #
      # input = {"x":1, "y":"xyz", "message":"Hello, world!"}
      # 
      # 'json' is JSON encoding:
      #   {"x":1,"y":"xyz","message":"Hello, world!"}
      # 
      # 'kvp' is "key=value" pairs, which is automatically detected as fields by Splunk:
      #   x="1" y="xyz" message="Hello, world!"
      # 
      # 'text' outputs the value of "message" as is, with "key=value" pairs for others:
      #   [x="1" y="xyz"] Hello, world!
      format json

      #
      # Buffering Parameters
      #

      # Standard parameters for buffering.  See documentation for details:
      #   http://docs.fluentd.org/articles/buffer-plugin-overview
      buffer_type memory
      buffer_queue_limit 16

      # buffer_chunk_limit: The maxium size of POST data in a single API call.
      # 
      # This value should be reasonablly small since the current implementation
      # of out_splunkapi converts a chunk to POST data on memory before API calls.
      # The default value should be good enough.
      buffer_chunk_limit 8m

      # flush_interval: The interval of API requests.
      # 
      # Make sure that this value is sufficiently large to make successive API calls.
      # Note that a different 'source' creates a different API POST, each of which may
      # take two or more seconds.  If you include "{TAG}" in the source parameter and
      # this 'match' section recieves many tags, a single flush may take long time.
      # (Run fluentd with -v to see verbose logs.)
      flush_interval 60s
    </match>

## Example

    # Input from applications
    <source>
      type forward
    </source>

    # Input from log files
    <source>
      type tail
      path /var/log/apache2/ssl_access.log
      tag ssl_access.log
      format /(?<message>.*)/
      pos_file /var/log/td-agent/ssl_access.log.pos
    </source>

    # fluent logs in text format
    <match fluent.*>
      type splunkapi
      protocol rest
      server splunk.example.com:8089
      auth admin:pass
      sourcetype fluentd
      format text
    </match>

    # log files in text format without timestamp
    <match *.log>
      type splunkapi
      protocol rest
      server splunk.example.com:8089
      auth admin:pass
      sourcetype log
      time_format none
      format text
    </match>

    # application logs in kvp format
    <match app.**>
      type splunkapi
      protocol rest
      server splunk.example.com:8089
      auth admin:pass
      sourcetype app
      format kvp
    </match>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
