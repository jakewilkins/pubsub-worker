# frozen_string_literal: true

require "thread"
require "redis"
require "json"

module PubsubWorker
  class Subscriber

    def self.start(channels)
      instance = new(channels)
      instance.start
      instance
    end

    attr_reader :channels, :queue, :redis, :thread

    def initialize(channels)
      @channels = channels
      @queue = Queue.new
      @redis = Redis.new(url: PubsubWorker.redis_url)
    end

    def start
      @thread = Thread.new do
        redis.subscribe(channels + [meta_channel, "events.ping"]) do |subscription|
          subscription.subscribe do |channel, subscriptions|
            PubsubWorker.log "Subscribed to #{channel} (#{subscriptions} subscriptions)"
          end

          subscription.message do |channel, message|
            if channel == "events.ping"
              redis = Redis.new(url: PubsubWorker.redis_url)
              redis.publish("events.pong", "pubsub_worker:#{meta_channel}")
              redis.disconnect!

              next
            end

            if channel == meta_channel
              process_meta_message(message)
              next
            end

            payload = JSON.parse(message) rescue {}
            if payload.empty?
              PubsubWorker.log "Received invalid payload: #{message}"
              next
            end

            queue << Job.new(channel, payload)
          end
        end
      end
    end

    def stop
      if thread.alive?
        thread.kill
      end
    end

    def running?
      thread.alive?
    end

    def process_meta_message(message)
      PubsubWorker.log "Processing meta message: #{message}"
      if message == "unsubscribe"
        redis.unsubscribe
      end
    end

    def meta_channel
      "meta:#{object_id}"
    end
  end
end
