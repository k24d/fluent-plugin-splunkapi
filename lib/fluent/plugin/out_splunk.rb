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

class SplunkOutput < BufferedOutput
  Plugin.register_output('splunk', self)

  config_param :host, :string, :default => nil # TODO: auto-detect
  config_param :protocol, :string, :default => 'storm'
  config_param :source, :string, :default => 'fluent:{TAG}'
  config_param :source_type, :string, :default => 'fluent'

  config_param :access_token, :string, :default => nil # TODO: required
  config_param :api_hostname, :string, :default => 'api.splunkstorm.com'
  config_param :project_id, :string, :default => nil # TODO: required

  def initialize
    super
    require 'net/http/persistent'
  end

  def configure(conf)
    super

    @base_url = "https://#{@api_hostname}/1/inputs/http?index=#{@project_id}&sourcetype=#{@source_type}"
    @base_url += "&host=#{@host}" if @host
  end

  def start
    super
    @http = Net::HTTP::Persistent.new 'fluentd-plugin-splunk'
    @http.headers['Content-Type'] = 'text/plain'
  end

  def shutdown
    @http.shutdown
    super
  end

  def format(tag, time, record)
    [tag, time, record].to_msgpack
  end

  def source_for_tag(tag)
    @source.sub('{TAG}', tag)
  end

  def chunk_to_buffers(chunk)
    # rebuild buffer for each tag
    buffers = {}
    chunk.msgpack_each do |tag, time, record|
      messages = (buffers[source_for_tag(tag)] ||= [])
      messages << "#{time}: #{record.to_json}\n"
    end
    return buffers
  end

  def write(chunk)
    chunk_to_buffers(chunk).each do |source, messages|
      uri = URI @base_url + "&source=#{source}"
      post = Net::HTTP::Post.new uri.request_uri
      post.basic_auth 'x', @access_token
      post.body = messages.join('')
      $log.debug "HTTP request: #{uri}"
      response = @http.request uri, post
      $log.debug "HTTP response: #{response.code}"
      $log.error response.message if response.code != "200"
    end
  end
end

end
