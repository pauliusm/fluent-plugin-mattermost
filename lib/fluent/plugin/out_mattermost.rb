require "fluent/plugin/output"
require 'fluent-logger'
require 'uri'
require 'net/http'
require 'net/https'
require 'logger'
require "json"

module Fluent
  module Plugin
    class MattermostOutput < Fluent::Plugin::Output
      Fluent::Plugin.register_output("mattermost", self)

      # Required parameter: The configuration must have this parameter like 'param1 10'.
      config_param :webhook_url, :string, default: nil

      config_param :channel_id, :string, default: nil

      config_param :tag, :bool, default: false

      config_param :enable_tls,  :bool, default: true

      def configure(conf)
        super
      end

      def start
        super
        log.info(webhook_url: @webhook_url, channel_id: @channel_id, tag: @tag, enable_tls: @enable_tls)
      end

      def write(chunk)
        begin
          if tag == true
            message = getTag(chunk)
          else
            message = getError(chunk)
          end

          post(message)
        rescue Timeout::Error => e
          log.warn "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          raise e # let Fluentd retry
        rescue => e
          log.error "out_mattermost:", :error => e.to_s, :error_class => e.class.to_s
          log.warn_backtrace e.backtrace
          # discard. @todo: add more retriable errors
        end
      end

      def post(payload)

        url = URI(@webhook_url)

        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = @enable_tls

        request = Net::HTTP::Post.new(url)
        request["Content-Type"] = "application/json"
        request.body = JSON.dump({
          "channel_id": @channel_id,
          "attachments": message(payload)
        })
        response = https.request(request)

        if response.read_body != "ok"
          log.error "response from mattermost: ", response.read_body
        else 
          puts response.read_body
        end
      end

      def message(record)
        payload = [{
                    "author_name": "Fluentd",
                    "thumb_url": "https://coralogix.com/wp-content/uploads/2020/04/fluentd-guide-700x430.png",
                    "color": "#FF0000",
                    "fields": [
                    {
                      "short":false,
                      "title":"Fluentd error",
                      "value": record
                    }]
                  }]
        return payload
      end

      def getTag(chunk)
        chunk.msgpack_each do |time, record|
          puts "#{time}\x01#{record}\n"
          return "#{time}\x01#{record}\n"
        end
      end

      def getError(chunk)
        messages = {}
        chunk.msgpack_each do |tag, time, record|
          channel = @channel_id
          messages[channel] ||= ''
          messages[channel] << "#{build_message(record)}\n"
        end
        messages.map do |channel, text|
          msg = {text: text}
          msg.merge!(channel: channel) if channel
          msg.merge!(common_payload)
        puts messages
        log.info "sono qui"
        return messages
      end

      def build_message(record)
        values = fetch_keys(record, @message_keys)
        @message % values
      end
      #def getError(chunk)
      #  chunk.open do |io|
      #    begin
      #      data = io.read
      #      records = Fluent::Engine.msgpack_unpacker(StringIO.new(data)).to_enum.to_a
      #      if records.key("input_tag").include?("error") || records.key("input_tag").include?("warn")
      #        puts record.key("message")
      #        return record.key("message")
      #      end
      #    end
      # end
      end
    end
  end
end
