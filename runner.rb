# frozen_string_literal: true

module PubsubWorker
  class Runner
    def self.start(queue)
      new(queue).tap {|r| r.start}
    end

    attr_reader :queue, :thread

    def initialize(queue)
      @queue = queue
    end

    def start
      @thread = Thread.new do
        loop do
          job = queue.pop
          PubsubWorker.log "Received job: #{job.channel} - #{job.description}"

          begin
            value = job.process!
            PubsubWorker.log "Job processed - #{value}"
          rescue Exception => boom
            PubsubWorker.log "Job errored: #{job.channel} - #{job.description} -- #{boom.message} #{boom.backtrace.join("\n")}"
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
      @thread.alive?
    end
  end
end
