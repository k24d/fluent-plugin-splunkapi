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

      # splnk server
      protocol storm
      access_token YOUR-ACCESS-TOKEN
      project_id YOUR-PROJECT-ID

      # event parameters
      host YOUR-HOSTNAME
      source fluent:{TAG}
      sourcetype fluent
    </match>

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
