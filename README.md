# Fluent::Plugin::Splunk

Fluent plugin for splunk output.

Only Splunk Storm is supported for now.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-splunk'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-splunk

## Usage

Put the following lines to your fluent.conf

    <match **>
      type splunk

      #
      # Splnk Server
      #

      # protocol: API protocol version.
      # values: 'storm'
      protocol storm

      # access_token: for Splunk Storm
      access_token YOUR-ACCESS-TOKEN

      # access_token: for Splunk Storm
      project_id YOUR-PROJECT-ID

      #
      # Event Parameters
      #

      # host: 'host' parameter passed to Splunk
      host YOUR-HOSTNAME

      # host: 'source' parameter passed to Splunk
      #
      # This option may include "{TAG}", which is replaced by fluet tags at runtime
      source fluent:{TAG}

      # sourcetype: 'sourcetype' parameter passed to Splunk
      sourcetype fluent

      # format: the text format of each event
      # value: 'json', 'field', or 'text'
      #
      # input = {"x":1, "y":"xyz", "message":"Hello, world!"}
      # 
      # 'json' is JSON encoding:
      #   {"x":1,"y":"xyz","message":"Hello, world!"}
      # 
      # 'field' is "key=value" pairs, which is automatically detected as fields by Splunk:
      #   x="1" y="xyz" message="Hello, world!"
      # 
      # 'text' is like field, but "message" is treated specially so as not to be a field:
      #   [x="1" y="xyz"] Hello, world!
      format json

      #
      # Buffe Parameters
      #

      # Standard parameters for buffering.  See documentation for details:
      #   http://docs.fluentd.org/articles/buffer-plugin-overview
      buffer_type memory
      buffer_queue_limit 16

      # buffer_chunk_limit: The maxium size of POST data in a single API call.
      # 
      # This value should be reasonablly small since the current implementation
      # of out_splunk converts a chunk to POST data on memory before API calls.
      # The default value should be good enough.
      buffer_chunk_limit 8m

      # flush_interval: The interval of API requests.
      # 
      # Make sure that this value is large enough to make successive API calls.
      # Note that a different source produces a different API POST, each of which
      # costs two or more seconds.  If you set "source fluent:{TAG}" above and
      # this 'match' section recieves many tags, the API requests may take long.
      # (Run fluentd with -v to see verbose logs.)
      flush_interval 60s
    </match>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
