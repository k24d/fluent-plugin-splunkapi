=begin

  Copyright (C) 2013 Keisuke Nishida

  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.

=end

module Fluent

class SplunkAPIOutput < BufferedOutput
  Plugin.register_output('splunkapi', self)

  config_param :protocol, :string, :default => 'rest'

  # for Splunk REST API
  config_param :server, :string, :default => 'localhost:8089'
  config_param :verify, :bool, :default => true
  config_param :auth, :string, :default => nil # TODO: required with rest

  # for Splunk Storm API
  config_param :access_token, :string, :default => nil # TODO: required with storm
  config_param :api_hostname, :string, :default => 'api.splunkstorm.com'
  config_param :project_id, :string, :default => nil # TODO: required with storm

  # Event parameters
  config_param :host, :string, :default => nil # TODO: auto-detect
  config_param :index, :string, :default => nil
  config_param :check_index, :bool, :default => true
  config_param :source, :string, :default => '{TAG}'
  config_param :sourcetype, :string, :default => 'fluent'

  # Formatting
  config_param :time_format, :string, :default => 'localtime'
  config_param :format, :string, :default => 'json'

  config_param :post_retry_max, :integer, :default => 5
  config_param :post_retry_interval, :integer, :default => 5

  def initialize
    super
    require 'net/http/persistent'
    require 'time'
  end

  def configure(conf)
    super

    case @source
    when '{TAG}'
      @source_formatter = lambda { |tag| tag }
    else
      @source_formatter = lambda { |tag| @source.sub('{TAG}', tag) }
    end

    case @time_format
    when 'none'
      @time_formatter = nil
    when 'unixtime'
      @time_formatter = lambda { |time| time.to_s }
    when 'localtime'
      @time_formatter = lambda { |time| Time.at(time).localtime }
    else
      @timef = TimeFormatter.new(@time_format, @localtime)
      @time_formatter = lambda { |time| @timef.format(time) }
    end

    case @format
    when 'json'
      @formatter = lambda { |record|
        record.to_json
      }
    when 'kvp'
      @formatter = lambda { |record|
        record_to_kvp(record)
      }
    when 'text'
      @formatter = lambda { |record|
        # NOTE: never modify 'record' directly
        record_copy = record.dup
        record_copy.delete('message')
        if record_copy.length == 0
          record['message']
        else
          "[#{record_to_kvp(record_copy)}] #{record['message']}"
        end
      }
    end

    if @protocol == 'rest'
      @username, @password = @auth.split(':')
      @base_url = "https://#{@server}/services/receivers/simple?sourcetype=#{@sourcetype}"
      @base_url += "&host=#{@host}" if @host
      @base_url += "&index=#{@index}" if @index
      @base_url += "&check-index=false" unless @check_index
    elsif @protocol == 'storm'
      @username, @password = 'x', @access_token
      @base_url = "https://#{@api_hostname}/1/inputs/http?index=#{@project_id}&sourcetype=#{@sourcetype}"
      @base_url += "&host=#{@host}" if @host
    end
  end

  def record_to_kvp(record)
    record.map {|k,v| v == nil ? "#{k}=" : "#{k}=\"#{v}\""}.join(' ')
  end

  def start
    super
    @http = Net::HTTP::Persistent.new 'fluentd-plugin-splunkapi'
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE unless @verify
    @http.headers['Content-Type'] = 'text/plain'
    $log.debug "initialized for #{@base_url}"
  end

  def shutdown
    # NOTE: call super before @http.shutdown because super may flush final output
    super

    @http.shutdown
    $log.debug "shutdown from #{@base_url}"
  end

  def format(tag, time, record)
    if @time_formatter
      time_str = "#{@time_formatter.call(time)}: "
    else
      time_str = ''
    end

    record.delete('time')
    event = "#{time_str}#{@formatter.call(record)}\n"

    [tag, event].to_msgpack
  end

  def chunk_to_buffers(chunk)
    buffers = {}
    chunk.msgpack_each do |tag, event|
      (buffers[@source_formatter.call(tag)] ||= []) << event
    end
    return buffers
  end

  def write(chunk)
    chunk_to_buffers(chunk).each do |source, messages|
      uri = URI @base_url + "&source=#{source}"
      post = Net::HTTP::Post.new uri.request_uri
      post.basic_auth @username, @password
      post.body = messages.join('')
      $log.debug "POST #{uri}"
      # retry up to :post_retry_max times
      1.upto(@post_retry_max) do |c|
        response = @http.request uri, post
        break if response.code != "503"
        $log.debug "=> #{response.code} (#{response.message})"
        sleep @post_retry_interval
        # fluentd will retry processing on exception
        # FIXME: this may duplicate logs with multiple buffers
        raise "#{uri}: #{response.message}" if c == @post_retry_max
      end
    end
  end
end

end
