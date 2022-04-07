# frozen_string_literal: true

require 'dotenv/load'

require_relative "subscriber"
require_relative "job"
require_relative "runner"

module PubsubWorker
  def self.redis_url
    ENV["REDIS_URL"]
  end

  def self.channels
    ENV["CHANNELS"].split(",")
  end

  def self.scripts_dir
    ENV["SCRIPTS_DIR"]
  end

  def self.start
    trap('INT') { PubsubWorker.stop }
    @subscriber = Subscriber.start(channels)
    @runner = Runner.start(@subscriber.queue)
    @stopped = false

    Process.setproctitle("pubsub worker: running")

    while !@stopped do
      unless @runner.running? && @subscriber.running?
        log "Shutting down...."
        stop
      end
    end
  end

  def self.stop
    Process.setproctitle("pubsub worker: stopping")
    log "Bye!"
    @subscriber.stop
    @runner.stop
    @stopped = true
  end

  def self.stopped?
    @stopped
  end

  def self.log(msg)
    $stdout.puts msg
  end

  def self.debug(msg)
    if ENV["DEBUG"]
      log(msg)
    end
  end
end

PubsubWorker.start
